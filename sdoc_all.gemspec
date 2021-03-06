# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sdoc_all"
  s.version = "1.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ivan Kuchin"]
  s.date = "2011-10-23"
  s.description = "WARNING: sdoc_all is no longer maintained, try doc gem.\n\nCommand line tool to get documentation for ruby, rails, gems and plugins in one place"
  s.executables = ["sdoc-all"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".autotest",
    ".tmignore",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "bin/sdoc-all",
    "lib/sdoc_all.rb",
    "lib/sdoc_all/base.rb",
    "lib/sdoc_all/config_error.rb",
    "lib/sdoc_all/core_extensions.rb",
    "lib/sdoc_all/file_list.rb",
    "lib/sdoc_all/generator/sdoc_all/sdoc_all_generator.rb",
    "lib/sdoc_all/generator/sdoc_all/templates/Rakefile",
    "lib/sdoc_all/generator/sdoc_all/templates/config.yml",
    "lib/sdoc_all/parts/gems.rb",
    "lib/sdoc_all/parts/paths.rb",
    "lib/sdoc_all/parts/plugins.rb",
    "lib/sdoc_all/parts/rails.rb",
    "lib/sdoc_all/parts/ruby.rb",
    "lib/sdoc_all/task.rb",
    "lib/tasks/sdoc_all_rake.rb",
    "sdoc_all.gemspec",
    "spec/sdoc_all/file_list_spec.rb",
    "spec/sdoc_all/gems_spec.rb",
    "spec/sdoc_all/paths_spec.rb",
    "spec/sdoc_all/plugins_spec.rb",
    "spec/sdoc_all/rails_spec.rb",
    "spec/sdoc_all/ruby_spec.rb",
    "spec/sdoc_all_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/toy/sdoc_all"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Documentation for everything"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, ["~> 2.3.0"])
      s.add_runtime_dependency(%q<colored>, [">= 0"])
      s.add_runtime_dependency(%q<progress>, [">= 0.0.8"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<rubigen>, [">= 0"])
      s.add_runtime_dependency(%q<sdoc>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_development_dependency(%q<rake-gem-ghost>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, ["~> 2.3.0"])
      s.add_dependency(%q<colored>, [">= 0"])
      s.add_dependency(%q<progress>, [">= 0.0.8"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rubigen>, [">= 0"])
      s.add_dependency(%q<sdoc>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
      s.add_dependency(%q<rake-gem-ghost>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, ["~> 2.3.0"])
    s.add_dependency(%q<colored>, [">= 0"])
    s.add_dependency(%q<progress>, [">= 0.0.8"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rubigen>, [">= 0"])
    s.add_dependency(%q<sdoc>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.1"])
    s.add_dependency(%q<rake-gem-ghost>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

