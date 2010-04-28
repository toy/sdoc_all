begin
  require 'jeweler'

  name = 'sdoc_all'
  summary = 'Documentation for everything'
  description = 'Command line tool to get documentation for ruby, rails, gems and plugins in one place'

  jewel = Jeweler::Tasks.new do |j|
    j.name = name
    j.summary = summary
    j.description = description
    j.homepage = "http://github.com/toy/#{name}"
    j.authors = ["Boba Fat"]
    j.add_dependency 'activesupport', '= 2.3.5'
    j.add_dependency 'colored'
    j.add_dependency 'progress', '>= 0.0.8'
    j.add_dependency 'rake'
    j.add_dependency 'rubigen'
    j.add_dependency 'sdoc'
  end

  Jeweler::GemcutterTasks.new

  require 'pathname'
  desc "Replace system gem with symlink to this folder"
  task 'ghost' do
    gem_path = Pathname(Gem.searcher.find(name).full_gem_path)
    current_path = Pathname('.').expand_path
    system('rm', '-r', gem_path)
    system('ln', '-s', current_path, gem_path)
  end

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
task :default => :spec
