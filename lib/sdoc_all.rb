#!/usr/bin/ruby

require 'fileutils'
require 'net/ftp'
require 'open3'
require 'pp'
require 'find'
require 'rubygems'
require 'activesupport'
require 'rake'
require 'nokogiri'
require 'progress'

__DIR__ = File.dirname(__FILE__)
$:.unshift(__DIR__) unless $:.include?(__DIR__) || $:.include?(File.expand_path(__DIR__))

class String
  def /(s)
    (Pathname.new(self) + s).to_s
  end
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

BASE_PATH = File.expand_path(File.dirname(__FILE__) / '..')
PUBLIC_PATH = BASE_PATH / 'public'
DOCS_PATH = BASE_PATH / 'docs'
SOURSES_PATH = BASE_PATH / 'sources'

class SdocAll
  def self.update_sources(options = {})
    Base.update_all_sources(options)
  end

  def self.build_documentation(options = {})
    tasks = Base.rdoc_tasks(options)

    options[:ruby] ||= '1.8.6'
    options[:exclude] ||= %w(gems/actionmailer gems/actionpack gems/activerecord gems/activeresource gems/activesupport gems/rails)

    selected_tasks = []
    selected_tasks << tasks.find_or_last_ruby(options[:ruby])
    selected_tasks << tasks.find_or_last_rails(options[:rails])
    tasks.gems.group_by{ |task| task.name_parts[0] }.sort_by{ |name, versions| name.downcase }.each do |name, versions|
      selected_tasks << versions.sort_by{ |version| version.name_parts[1] }.last
    end
    tasks.plugins.sort_by{ |task| task.name_parts[0] }.each do |task|
      selected_tasks << task
    end

    selected_tasks.delete_if do |task|
      options[:exclude].any?{ |exclude| task.doc_path[exclude] }
    end

    selected_tasks.each_with_progress('Building documentation', &:run)

    Dir.chdir(DOCS_PATH) do
      remove_if_present(PUBLIC_PATH)

      pathes = []
      titles = []
      urls = []
      selected_tasks.each do |rdoc_task|
        doc_path = DOCS_PATH / rdoc_task.doc_path
        if File.file?(doc_path / 'index.html')
          pathes << rdoc_task.doc_path
          titles << rdoc_task.title
          urls << "/docs/#{rdoc_task.doc_path}"
        end
      end

      cmd = %w(sdoc-merge)
      cmd << '-o' << PUBLIC_PATH
      cmd << '-t' << 'all'
      cmd << '-n' << titles.join(',')
      cmd << '-u' << urls.join(' ')
      system(*cmd + pathes)

      File.symlink(DOCS_PATH, PUBLIC_PATH / 'docs')
      FileUtils.copy(BASE_PATH / 'favicon.ico', PUBLIC_PATH)
    end
  end

  class RdocTasks
    include Enumerable
    def initialize
      @tasks = {}
    end

    def add(klass, options = {})
      type = klass.name.split('::').last.downcase.to_sym
      (@tasks[type] ||= []) << RdocTask.new(options)
    end

    def length
      @tasks.sum{ |type, tasks| tasks.length }
    end
    def each(&block)
      @tasks.each do |type, tasks|
        tasks.each(&block)
      end
    end

    def method_missing(method, *args, &block)
      if /^find_or_(first|last)_(.*)/ === method.to_s
        tasks = @tasks[$2.to_sym] || super
        name = args[0]
        name && tasks.find{ |task| task.name_parts.any?{ |part| part[name] } } || ($1 == 'first' ? tasks.first : tasks.last)
      else
        @tasks[method] || super
      end
    end
  end

  class RdocTask
    def initialize(options = {})
      @options = options
      @options[:title] = @options[:doc_path].sub('s/', ' — ') if @options[:doc_path]
    end

    def src_path
      @options[:src_path]
    end

    def doc_path
      @options[:doc_path]
    end

    def pathes
      @options[:pathes]
    end

    def title
      @options[:title]
    end

    def main
      @options[:main]
    end

    def name_parts
      @options[:name_parts]
    end

    def run
      unless File.directory?(DOCS_PATH / doc_path)
        Dir.chdir(SOURSES_PATH / src_path) do
          cmd = %w(sdoc)
          cmd << '-o' << DOCS_PATH / doc_path
          cmd << '-t' << title
          cmd << '-T' << 'direct'
          cmd << '-m' << main if main
          system(*cmd + pathes)
        end
      end
    end
  end
end

require 'sdoc_all/base'
require 'sdoc_all/ruby'
require 'sdoc_all/gems'
require 'sdoc_all/rails'
require 'sdoc_all/plugins'

SdocAll.update_sources
SdocAll.build_documentation
