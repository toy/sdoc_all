require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'echoe'

version = YAML.load_file(File.join(File.dirname(__FILE__), 'VERSION.yml')).join('.') rescue nil

Echoe.new('sdoc_all', version) do |p|
  p.author = "toy"
  p.summary = "documentation for everything"
  p.description = "Command line tool to get documentation for ruby, rails, gems and plugins in one place"
  p.email = "ivan@workisfun.ru"
  p.url = "http://github.com/toy/sdoc_all"
  p.runtime_dependencies << 'activesupport'
  p.runtime_dependencies << 'rake'
  p.runtime_dependencies << 'progress >=0.0.8'
  # TODO: sdoc or voloko-sdoc
  p.project = 'toytoy'
end
