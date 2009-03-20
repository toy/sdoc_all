#!/usr/bin/ruby

require 'fileutils'
require 'net/ftp'
require 'open3'
require 'pp'
require 'rubygems'
require 'rake'
require 'progress'

class String
  def /(s)
    File.join(self, s)
  end
end

BASE_PATH = File.expand_path(File.dirname(__FILE__))
DOCS_PATH = BASE_PATH / 'docs'
SOURSES_PATH = BASE_PATH / 'sources'

class RdocAll
  class << self
    def update_sources(options = {})
      Base.update_all_sources(options)
    end

    def build_documentation(options = {})
      Base.build_documentation(options)
    end
  end
end

class RdocAll::Base
  class << self
    def inherited(subclass)
      (@subclasses ||= []) << subclass
    end

    def update_all_sources(options = {})
      Dir.chdir(SOURSES_PATH) do
        @subclasses.each do |subclass|
          subclass.update_sources(options)
        end
      end
    end

    def build_documentation(options = {})
      Dir.chdir(SOURSES_PATH) do
        @@rdoc_tasks = []

        @subclasses.each do |subclass|
          subclass.add_rdoc_tasks
        end

        to_clear = Dir.glob(DOCS_PATH / '*' / '*')
        @@rdoc_tasks.each do |rdoc_task|
          doc_path = DOCS_PATH / rdoc_task[:base_path]
          to_clear.delete_if{ |path| path[0, doc_path.length] == doc_path }
        end
        to_clear.each do |path|
          remove_if_present(path)
        end

        @@rdoc_tasks.each_with_progress('Building docs') do |rdoc_task|
          Dir.chdir(rdoc_task[:base_path]) do
            doc_path = DOCS_PATH / rdoc_task[:base_path]
            remove_if_present(doc_path) if Dir[doc_path / '*'].empty? || options[:force]
            cmd = %w(hanna)
            cmd << '-o' << doc_path
            cmd << '-t' << rdoc_task[:title]
            system(*cmd + rdoc_task[:source_pathes])
          end
        end
      end
    end

  protected

    def add_rdoc_task(base_path, source_pathes = [])
      @@rdoc_tasks << {:base_path => base_path, :source_pathes => source_pathes, :title => base_path.sub('s/', ' — ')}
    end

    def with_env(key, value)
      old_value, ENV[key] = ENV[key], value
      yield
    ensure
      ENV[key] = old_value
    end

    def remove_if_present(path)
      FileUtils.remove_entry(path) if File.exist?(path)
    end
  end
end

class RdocAll::Ruby < RdocAll::Base
  class << self
    def tars
      Dir['ruby-*.tar.bz2']
    end

    def rubys
      Dir['ruby-*'].select{ |path| File.directory?(path) }
    end

    def update_sources(options = {})
      to_clear = tars
      Net::FTP.open('ftp.ruby-lang.org') do |ftp|
        ftp.debug_mode = true
        ftp.passive = true
        ftp.login
        ftp.chdir('/pub/ruby')
        ftp.list('ruby-*.tar.bz2').each do |line|
          tar_path, tar = File.split(line.split.last)
          to_clear.delete(tar)
          remove_if_present(tar) if options[:force]
          unless File.exist?(tar)
            ftp.chdir('/pub/ruby' / tar_path)
            ftp.getbinaryfile(tar)
          end
        end
      end
      to_clear.each do |tar|
        remove_if_present(tar)
      end

      to_clear = rubys
      tars.each do |tar|
        ruby = File.basename(tar, '.tar.bz2')
        to_clear.delete(ruby)
        remove_if_present(ruby) if options[:force]
        unless File.directory?(ruby)
          system('tar', '-xjf', tar)
        end
      end
      to_clear.each do |ruby|
        remove_if_present(ruby)
      end
    end

    def add_rdoc_tasks
      rubys.each do |ruby|
        add_rdoc_task(ruby)
      end
    end
  end
end

class RdocAll::Gems < RdocAll::Base
  class << self
    def each(&block)
      Gem.source_index.each(&block)
    end

    def update_sources(options = {})
    end

    def add_rdoc_tasks
      each do |gem_name, spec|
        add_rdoc_task('gems' / gem_name, spec.require_paths + spec.extra_rdoc_files)
      end
    end
  end
end

class RdocAll::Rails < RdocAll::Base
  class << self
    def each
      Gem.source_index.search(Gem::Dependency.new('rails', :all)).each do |spec|
        yield spec.full_name, spec.version.to_s
      end
    end

    def update_sources(options = {})
      to_clear = Dir['rails-*']
      each do |rails, version|
        to_clear.delete(rails)
        remove_if_present(rails) if options[:force]
        unless File.directory?(rails)
          with_env 'VERSION', version do
            system('rails', rails, '--freeze')
          end
        end
      end
      to_clear.each do |rails|
        remove_if_present(rails)
      end
    end

    def add_rdoc_tasks
      each do |rails, version|
        Dir.chdir(rails) do
          pathes = Rake::FileList.new
          File.open('vendor/rails/railties/lib/tasks/documentation.rake') do |f|
            true until f.readline['Rake::RDocTask.new("rails")']
            until (line = f.readline.strip) == '}'
              if line['rdoc.rdoc_files.include']
                pathes.include(line[/'(.*)'/, 1])
              elsif line['rdoc.rdoc_files.exclude']
                pathes.exclude(line[/'(.*)'/, 1])
              end
            end
          end
          add_rdoc_task(rails, pathes.resolve)
        end
      end
    end
  end
end

class RdocAll::Plugins < RdocAll::Base
  class << self
    def each(&block)
      Dir['plugins/*'].each(&block)
    end

    def update_sources(options = {})
      each do |plugin|
        Dir.chdir(plugin) do
          system('git fetch origin && git reset --hard HEAD')
        end
      end
    end

    def add_rdoc_tasks
      each do |plugin|
        Dir.chdir(plugin) do
          pathes = Rake::FileList.new
          pathes.include('lib/**/*.rb')
          pathes.include('README*')
          pathes.include('CHANGELOG*')
          add_rdoc_task(plugin, pathes.resolve)
        end
      end
    end
  end
end

RdocAll.update_sources
# RdocAll.build_documentation
