require 'rake'
require 'jeweler'
require 'rake/gem_ghost_task'
require 'rspec/core/rake_task'

name = 'sdoc_all'

Jeweler::Tasks.new do |gem|
  gem.name = name
  gem.summary = %Q{Documentation for everything}
  gem.description = %Q{WARNING: sdoc_all is no longer maintained, try doc gem.\n\nCommand line tool to get documentation for ruby, rails, gems and plugins in one place}
  gem.homepage = "http://github.com/toy/#{name}"
  gem.license = 'MIT'
  gem.authors = ['Ivan Kuchin']

  gem.add_runtime_dependency 'activesupport', '~> 2.3.0'
  gem.add_runtime_dependency 'colored'
  gem.add_runtime_dependency 'progress', '>= 0.0.8'
  gem.add_runtime_dependency 'rake'
  gem.add_runtime_dependency 'rubigen'
  gem.add_runtime_dependency 'sdoc'

  gem.add_development_dependency 'jeweler', '~> 1.5.1'
  gem.add_development_dependency 'rake-gem-ghost'
  gem.add_development_dependency 'rspec'
end
Jeweler::RubygemsDotOrgTasks.new
Rake::GemGhostTask.new

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--colour --format progress']
  spec.pattern = 'spec/**/*_spec.rb'
end
task :default => :spec
