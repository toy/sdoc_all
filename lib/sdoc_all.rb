#!/usr/bin/ruby

require 'pathname'
require 'fileutils'
require 'find'
require 'digest'

require 'rubygems'
require 'activesupport'
require 'rake'
require 'progress'

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
end

class SdocAll
  module ClassMethods
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
      begin
        read_config
        tasks = Base.tasks(:update => update? || options[:update])

        if last_build_sdoc_version.nil? || last_build_sdoc_version != current_sdoc_version
          Base.remove_if_present(Base.docs_path)
        else
          Dir.chdir(Base.docs_path) do
            to_delete = Dir.glob('*')
            tasks.each do |task|
              to_delete.delete(task.doc_path)
            end
            to_delete.each do |path|
              Base.remove_if_present(path)
            end
          end
        end

        tasks.each_with_progress('docs') do |task|
          task.run(options)
        end

        hash = Digest::SHA1.hexdigest(tasks.map(&:hash).inspect + title.to_s)
        created_hash = config_hash_path.read rescue nil

        if hash != created_hash
          Dir.chdir(Base.docs_path) do
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
                File.symlink(Base.docs_path, Base.public_path + 'docs')
                config_hash_path.open('w') do |f|
                  f.write(hash)
                end
                last_build_sdoc_version_path.open('w') do |f|
                  f.write(current_sdoc_version)
                end
              end
            end
          end
        end
      rescue ConfigError => e
        STDERR.puts e.to_s
      end
    end

    def read_config
      Base.clear
      config = YAML.load_file('config.yml').symbolize_keys rescue {}

      min_update_interval = if config[:min_update_interval].to_s[/(\d+)\s*(.*)/]
        value = $1.to_i
        case $2
        when /^d/
          value.days
        when /^h/
          value.hours
        when /^m/
          value.minutes
        else
          value.seconds
        end
      else
        1.hour
      end

      created = last_build_sdoc_version_path.mtime rescue nil
      @update = created.nil? || created < min_update_interval.ago

      @title = config[:title]

      if config[:sdoc] && config[:sdoc].is_a?(Array) && config[:sdoc].length > 0
        errors = []
        config[:sdoc].each do |entry|
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
          raise ConfigError.new(errors)
        end
      else
        raise ConfigError.new("config did not specify what to document")
      end
    end
  end
  extend ClassMethods
end

require 'sdoc_all/base.rb'
require 'sdoc_all/task.rb'
require 'sdoc_all/config_error.rb'

Dir.entries("#{__DIR__}/sdoc_all").grep(/\.rb$/).each do |file|
  require "sdoc_all/#{file}"
end
