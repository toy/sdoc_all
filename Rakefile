require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'echoe'

version = YAML.load_file(File.join(File.dirname(__FILE__), 'VERSION.yml')).join('.') rescue nil

Echoe.new('sdoc_all', version) do |p|
  p.author = "toy"
  p.summary = "Command line tool to get documentation for ruby, rails, gems and plugins in one place"
  p.url = "http://github.com/toy/sdoc_all"
  p.runtime_dependencies = %w(sdoc activesupport rake progress)
  p.project = 'toytoy'
end
