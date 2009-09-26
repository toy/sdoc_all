require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'echoe'

version = YAML.load_file(Pathname(__FILE__).dirname + 'VERSION.yml').join('.') rescue nil

echoe = Echoe.new('sdoc_all', version) do |p|
  p.author = 'toy'
  p.summary = 'documentation for everything'
  p.description = 'Command line tool to get documentation for ruby, rails, gems and plugins in one place'
  p.email = 'ivan@workisfun.ru'
  p.url = 'http://github.com/toy/sdoc_all'
  p.runtime_dependencies << 'activesupport'
  p.runtime_dependencies << 'rake'
  p.runtime_dependencies << 'progress >=0.0.8'
  p.runtime_dependencies << 'sdoc'
  p.runtime_dependencies << 'rubigen'
  p.project = 'toytoy'
end

desc "Replace system gem with symlink to this folder"
task 'ghost' do
  gem_path = Pathname(Gem.searcher.find(echoe.name).full_gem_path)
  current_path = Pathname('.').expand_path
  cmd = gem_path.writable? && gem_path.parent.writable? ? %w() : %w(sudo)
  system(*cmd + %W[rm -r #{gem_path}])
  system(*cmd + %W[ln -s #{current_path} #{gem_path}])
end
