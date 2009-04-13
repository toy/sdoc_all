#!/usr/bin/ruby

require 'fileutils'
require 'net/ftp'
require 'open3'
require 'pp'
require 'rubygems'
require 'activesupport'
require 'rake'
require 'nokogiri'
require 'progress'
# require 'sqlite3'
require 'erubis'

__DIR__ = File.dirname(__FILE__)
$:.unshift(__DIR__) unless $:.include?(__DIR__) || $:.include?(File.expand_path(__DIR__))

class String
  def /(s)
    File.join(self, s)
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
DOCS_PATH = BASE_PATH / 'public' / 'docs'
SOURSES_PATH = BASE_PATH / 'sources'

class RdocAll
  def self.update_sources(options = {})
    Base.update_all_sources(options)
  end

  def self.build_documentation(options = {})
    tasks = Base.rdoc_tasks(options)

    # tasks.each_with_progress('Building documentation', &:run)

    # selected_tasks = []
    # selected_tasks << tasks.find_or_first_ruby(options[:ruby])
    # # selected_tasks += tasks.gems
    # selected_tasks << tasks.find_or_first_rails(options[:rails])
    # selected_tasks += tasks.plugins

    links = []
    tasks.each_with_progress('Reading indexes') do |rdoc_task|
      doc_path = DOCS_PATH / rdoc_task.base_path
      if File.file?(doc_path / 'index.html')
        links << {
          :url => '/docs' / rdoc_task.base_path / 'index.html',
          :text => rdoc_task.title
        }
      end
    end

    template = Erubis::Eruby.new(File.read(BASE_PATH / 'view' / 'list.rhtml'))
    context = Erubis::Context.new(:links => links)
    File.open(BASE_PATH / 'public' / 'index.html', 'w') do |f|
      f.write(template.evaluate(context))
    end

    # is = IndexStore.new
    # is.clear
    # tasks.each_with_index_and_progress('Reading indexes') do |rdoc_task, i|
    #   doc_path = DOCS_PATH / rdoc_task.base_path
    #   if File.file?(doc_path / 'index.html')
    #     %w(file class method).each do |type|
    #       if html = File.read(doc_path / "fr_#{type}_index.html")
    #         doc = Nokogiri::HTML(html)
    #         doc.xpath('.//ol[@id = "index-entries"]/li').each do |entry|
    #           sort_field = [(entry.xpath('./a').first || entry.xpath('./span').first).content, i].join(',')
    #           entry_html = entry.to_s.gsub('href="', "href=\"/docs/#{rdoc_task.base_path}/")
    #           is.add_entry(rdoc_task.base_path, type, sort_field, entry_html)
    #         end
    #       end
    #     end
    #   end
    # end
  end

  class IndexStore
    def initialize
      create
    end

    def db
      @db ||= SQLite3::Database.new(BASE_PATH / 'indexes.db')
    end

    def create
      db.execute(%Q{
        CREATE TABLE IF NOT EXISTS "entries" (
          "document" TEXT,
          "type" TEXT,
          "sort_field" TEXT,
          "html" TEXT
        )
      })
    end

    def clear
      db.execute('DROP TABLE IF EXISTS "entries"')
      create
    end

    def add_entry(document, type, sort_field, html)
      p [document, type, sort_field, html]
      # db.execute('INSERT INTO "entries" (document, type, sort_field, html) VALUES (?, ?, ?, ?)', document, type, sort_field, html)
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
      # if /^find_or_(first|last)_(.*)/ ===  method.to_s
      #   tasks = @tasks[$2.to_sym] || super
      #   name = args[0]
      #   name && tasks.find{ |task| task.base_path[name] } || ($1 == 'first' ? tasks.first : tasks.last)
      # else
      @tasks[method] || super
      # end
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

require 'rdoc_all/base'
require 'rdoc_all/ruby'
require 'rdoc_all/gems'
require 'rdoc_all/rails'
require 'rdoc_all/plugins'

# RdocAll.update_sources
RdocAll.build_documentation
