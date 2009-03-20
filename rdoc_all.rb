#!/usr/bin/ruby

require 'fileutils'
require 'net/ftp'
require 'open3'
require 'pp'
require 'rubygems'
require 'rake'
# require 'progress'

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
      @rdoc_tasks = []
      Dir.chdir(SOURSES_PATH) do
        @subclasses.each do |subclass|
          subclass.add_rdoc_tasks
        end
      end
    end

  protected

    def add_rdoc_task(base_path, source_pathes = [])
      p [base_path, source_pathes.length]
      # Dir.chdir(path) do
      #   puts "Building #{path} documentation"
      #   Dir.rmdir(DOC_DIR / path) if File.directory?(DOC_DIR / path) && Dir[DOC_DIR / path / '*'].empty?
      #   system('hanna', '-o', DOC_DIR / path, '-t', path.sub('s/', ' — '), *pathes)
      # end
    end

    def with_env(key, value)
      old_value, ENV[key] = ENV[key], value
      yield
    ensure
      ENV[key] = old_value
    end
  end
end

class RdocAll::Ruby < RdocAll::Base
  class << self
    def each(&block)
      Dir['ruby-*'].select{ |path| File.directory?(path) }.each(&block)
    end

    def update_sources(options = {})
      Net::FTP.open('ftp.ruby-lang.org') do |ftp|
        ftp.debug_mode = true
        ftp.passive = true
        ftp.login
        ftp.chdir('/pub/ruby')
        ftp.list('ruby*.tar.bz2').each do |line|
          tar_path, tar = File.split(line.split.last)
          FileUtils.remove_entry(tar) if options[:force]
          unless File.exist?(tar)
            ftp.chdir('/pub/ruby' / tar_path)
            ftp.getbinaryfile(tar)
          end
        end
      end

      Dir['ruby-*.tar.bz2'].each do |tar|
        ruby = File.basename(tar, '.tar.bz2')
        FileUtils.remove_entry(ruby) if options[:force]
        unless File.directory?(ruby)
          system('tar', '-xjf', tar)
        end
      end
    end

    def add_rdoc_tasks
      each do |ruby|
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
      each do |rails, version|
        FileUtils.remove_entry(rails) if options[:force]
        unless File.directory?(rails)
          with_env 'VERSION', spec.version.to_s do
            system("rails", rails, '--freeze')
          end
        end
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

RdocAll.build_documentation
