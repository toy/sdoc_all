# encoding: utf-8

require 'pathname'
require 'fileutils'
require 'find'
require 'digest'

require 'rubygems'
require 'active_support'
require 'rake'
require 'progress'
require 'colored'

__DIR__ = File.dirname(__FILE__)
$:.unshift(__DIR__) unless $:.include?(__DIR__) || $:.include?(File.expand_path(__DIR__))

class Array
  def sort_by!(&block)
    replace(sort_by(&block))
  end
end

class Pathname
  def write(s)
    open('w') do |f|
      f.write(s)
    end
  end
  def hidden?
    basename.to_s =~ /^\./
  end
  def visible?
    !hidden?
  end
end

class String
  def shrink(max_length)
    if length > max_length
      "#{self[0, max_length - 1]}…"
    else
      self
    end
  end
end

class SdocAll
  class << self
    def update?
      @update.nil? || @update
    end

    def title
      @title.present? ? @title : 'ruby related reference'
    end

    def last_build_sdoc_version_path
      Base.base_path + 'sdoc.version'
    end

    def last_build_sdoc_version
      last_build_sdoc_version_path.read rescue nil
    end

    def current_sdoc_version
      Gem.searcher.find('sdoc').version.to_s
    end

    def config_hash_path
      Base.public_path + 'config.hash'
    end

    def run(options = {})
      Base.dry_run! if options[:dry_run]
      Base.verbose_level = options[:verbose_level]
      Progress.lines = true if Base.verbose_level >= 1
      begin
        read_config
        tasks = Base.tasks(:update => update? || options[:update])

        if last_build_sdoc_version.nil? || last_build_sdoc_version != current_sdoc_version
          puts "sdoc version changed - rebuilding all docs".red unless last_build_sdoc_version.nil?
          Base.remove_if_present(Base.docs_path)
        else
          Base.chdir(Base.docs_path) do
            to_delete = Dir.glob('*') - tasks.map(&:occupied_doc_pathes).flatten
            to_delete.each do |path|
              Base.remove_if_present(path)
            end
          end
        end

        tasks.with_progress('sdoc').each do |task|
          Progress.start(task.title) do
            task.run(options)
          end
        end

        config_hash = Digest::SHA1.hexdigest(tasks.map(&:config_hash).inspect + title.to_s)
        created_hash = config_hash_path.read rescue nil

        if config_hash != created_hash
          Base.chdir(Base.docs_path) do
            paths = []
            titles = []
            urls = []
            tasks.each do |task|
              doc_path = Base.docs_path + task.doc_path
              if File.file?(doc_path + 'index.html')
                paths << task.doc_path
                titles << task.title
                urls << "docs/#{task.doc_path}"
              end
            end

            if paths.present?
              Base.remove_if_present(Base.public_path)

              cmd = %w(sdoc-merge)
              cmd << '-o' << Base.public_path
              cmd << '-t' << title
              cmd << '-n' << titles.join(',')
              cmd << '-u' << urls.join(' ')
              Base.system(*cmd + paths)

              if Base.public_path.directory?
                (Base.public_path + 'docs').make_symlink(Base.docs_path.relative_path_from(Base.public_path))
                config_hash_path.open('w') do |f|
                  f.write(config_hash)
                end
                last_build_sdoc_version_path.open('w') do |f|
                  f.write(current_sdoc_version)
                end
              end
            end
          end
        end
      rescue ConfigError => e
        abort e.to_s.red.bold
      end
    end

    def read_config
      Base.clear
      config = YAML.load_file('config.yml').symbolize_keys rescue {}

      min_update_interval = if config[:min_update_interval].to_s[/(\d+)\s*(.*)/]
        $1.to_i.send({'d' => :days, 'h' => :hours, 'm' => :minutes}[$2[0, 1].downcase] || :seconds)
      else
        1.hour
      end

      created = last_build_sdoc_version_path.mtime rescue nil
      @update = created.nil? || created < min_update_interval.ago

      @title = config[:title]

      if config[:sdoc] && config[:sdoc].is_a?(Array) && config[:sdoc].length > 0
        errors = []
        config[:sdoc].with_progress('reading config').each do |entry|
          begin
            if entry.is_a?(Hash)
              if entry.length == 1
                Base.to_document(*entry.shift)
              else
                raise ConfigError.new("config entry #{entry.inspect} can not be understood - watch ident")
              end
            else
              Base.to_document(entry, {})
            end
          rescue ConfigError => e
            errors << e
          end
        end
        if errors.present?
          raise ConfigError.new(errors.join("\n"))
        end
      else
        raise ConfigError.new("config did not specify what to document")
      end
    end
  end
end

require 'sdoc_all/base'
require 'sdoc_all/task'
require 'sdoc_all/config_error'
require 'sdoc_all/file_list'

Dir.entries("#{__DIR__}/sdoc_all/parts").grep(/\.rb$/).each do |file|
  require "sdoc_all/parts/#{file}"
end
