#!/usr/bin/ruby

require 'fileutils'
require 'net/ftp'
require 'open3'
require 'pp'
require 'rubygems'
require 'rake'
require 'activesupport'
require 'progress'

class String
  def /(s)
    File.join(self, s)
  end
end

DOCS_PATH = File.dirname(__FILE__) / 'docs'
SOURSES_PATH = File.dirname(__FILE__) / 'sources'

class RdocAll
  class << self
    def update_source(options = {})
      Base.update_all_sources(options)
    end

    def document(options = {})
      Base.document_all(options)
    end
  end
end

class RdocAll::Base
  class << self
    define_method(:update_sources) {}
    define_method(:document) {}

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

    # def document_all(options = {})
    #   Dir.chdir(SOURSES_PATH) do
    #     @subclasses.each do |subclass|
    #       subclass.document
    #     end
    #   end
    # end

  protected

    def hanna(path, pathes = [])
      p path
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

    def document
      # fix
      # Dir['ruby-*.tar.bz2'].each do |ruby_tar|
      #   ruby = File.basename(ruby_tar, '.tar.bz2')
      #   system('tar', '-xjf', ruby_tar) unless File.directory?(ruby)
      #   hanna(ruby)
      # end
    end
  end
end

class RdocAll::Gems < RdocAll::Base
  class << self
    def document
      # Gem.source_index.each do |gem_name, spec|
      #   hanna('gems' / gem_name, spec.require_paths + spec.extra_rdoc_files)
      # end
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

    def document
      # Gem.source_index.search(Gem::Dependency.new('rails', :all)).each do |spec|
      #   rails = spec.full_name
      #   unless File.directory?(rails)
      #     with_env 'VERSION', spec.version.to_s do
      #       system("rails", rails, '--freeze')
      #     end
      #   end
      #
      #   pathes = Rake::FileList.new
      #   documentation_rake = rails / 'vendor/rails/railties/lib/tasks/documentation.rake'
      #   doc_rails_task = false
      #   File.readlines(documentation_rake).each do |line|
      #     doc_rails_task = true if line['Rake::RDocTask.new("rails")']
      #     doc_rails_task = false if line.strip == '}'
      #     if doc_rails_task
      #       if line['rdoc.rdoc_files.include']
      #         pathes.include(line[/'(.*)'/, 1])
      #       elsif line['rdoc.rdoc_files.exclude']
      #         pathes.exclude(line[/'(.*)'/, 1])
      #       end
      #     end
      #   end
      #   hanna(rails, pathes)
      # end
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

    def document
      # Dir['plugins/*'].each do |plugin|
      #   pathes = Rake::FileList.new
      #   pathes.include('lib/**/*.rb')
      #   pathes.include('README*')
      #   pathes.include('CHANGELOG*')
      #   hanna(plugin, pathes)
      # end
    end
  end
end

RdocAll.update_sources
