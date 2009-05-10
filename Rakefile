require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'echoe'

version = YAML.load_file(File.join(File.dirname(__FILE__), 'VERSION.yml')).join('.') rescue nil

echoe = Echoe.new('sdoc_all', version) do |p|
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

desc "Replace system gem with symlink to this folder"
task 'ghost' do
  path = Gem.searcher.find(echoe.name).full_gem_path
  system 'sudo', 'rm', '-r', path
  symlink File.expand_path('.'), path
end

begin
  require 'spec/rake/spectask'

  task :default => :spec
  task :test

  desc "Run the specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_opts = ['--options', "spec/spec.opts"]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
rescue LoadError
  puts <<-EOS
  To use rspec for testing you must install rspec gem:
    gem install rspec
  EOS
end
