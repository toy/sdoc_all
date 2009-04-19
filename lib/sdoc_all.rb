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
  def self.run(options = {})
    add_default_options!(options)

    Base.update_all_sources(options)

    tasks = Base.rdoc_tasks(options)

    selected_tasks = []
    selected_tasks << tasks.find_or_last_ruby(options[:ruby])
    selected_tasks << tasks.find_or_last_rails(options[:rails])
    tasks.gems.group_by{ |task| task.name_parts[0] }.sort_by{ |name, versions| name.downcase }.each do |name, versions|
      selected_tasks << versions.sort_by{ |version| version.name_parts[1] }.last
    end
    tasks.plugins.sort_by{ |task| task.name_parts[0] }.each do |task|
      selected_tasks << task
    end

    if options[:exclude].is_a?(Array)
      selected_tasks.delete_if do |task|
        options[:exclude].any?{ |exclude| task.doc_path[exclude] }
      end
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
    end
  end

private

  def self.add_default_options!(options)
    options[:base_path] = Pathname.new(options[:base_path] || Dir.pwd).freeze
    options[:public_path] = Pathname.new(options[:public_path] || options[:base_path] + 'public').freeze
    options[:docs_path] = Pathname.new(options[:docs_path] || options[:base_path] + 'docs').freeze
    options[:sources_path] = Pathname.new(options[:sources_path] || options[:base_path] + 'sources').freeze

    options[:exclude] ||= %w(gems/actionmailer gems/actionpack gems/activerecord gems/activeresource gems/activesupport gems/rails)
    options[:plugins_path] = Pathname.new(options[:plugins_path] || File.expand_path('~/.plugins')).freeze
  end
end

require 'sdoc_all/base'
require 'sdoc_all/ruby'
require 'sdoc_all/gems'
require 'sdoc_all/rails'
require 'sdoc_all/plugins'
require 'sdoc_all/rdoc_task'
require 'sdoc_all/rdoc_tasks'
