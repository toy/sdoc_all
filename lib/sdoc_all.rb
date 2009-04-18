#!/usr/bin/ruby

require 'fileutils'
require 'find'

require 'rubygems'
require 'activesupport'
require 'rake'
require 'progress'

__DIR__ = File.dirname(__FILE__)
$:.unshift(__DIR__) unless $:.include?(__DIR__) || $:.include?(File.expand_path(__DIR__))

class SdocAll
  def self.update_sources(options = {})
    add_default_options!(options)

    Base.update_all_sources(options)
  end

  def self.build_documentation(options = {})
    add_default_options!(options)

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

    selected_tasks.each_with_progress('Building documentation') do |task|
      task.run(options)
    end

    Dir.chdir(options[:docs_path]) do
      Base.remove_if_present(options[:public_path])

      pathes = []
      titles = []
      urls = []
      selected_tasks.each do |rdoc_task|
        doc_path = options[:docs_path] + rdoc_task.doc_path
        if File.file?(doc_path + 'index.html')
          pathes << rdoc_task.doc_path
          titles << rdoc_task.title
          urls << "/docs/#{rdoc_task.doc_path}"
        end
      end

      cmd = %w(sdoc-merge)
      cmd << '-o' << options[:public_path]
      cmd << '-t' << 'all'
      cmd << '-n' << titles.join(',')
      cmd << '-u' << urls.join(' ')
      system(*cmd + pathes)

      File.symlink(options[:docs_path], options[:public_path] + 'docs')
      File.symlink(options[:base_path] + 'favicon.ico', options[:public_path] + 'favicon.ico') if File.exists?(options[:base_path] + 'favicon.ico')
    end
  end

private

  def self.add_default_options!(options)
    # options.replace({}.merge(options))
    options[:base_path] = Pathname.new(options[:base_path] || Dir.pwd).freeze
    options[:public_path] = Pathname.new(options[:public_path] || options[:base_path] + 'public').freeze
    options[:docs_path] = Pathname.new(options[:docs_path] || options[:base_path] + 'docs').freeze
    options[:sources_path] = Pathname.new(options[:sources_path] || options[:base_path] + 'sources').freeze
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

    def run(options = {})
      unless File.directory?(options[:docs_path] + doc_path)
        Dir.chdir(options[:sources_path] + src_path) do
          cmd = %w(sdoc)
          cmd << '-o' << options[:docs_path] + doc_path
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
