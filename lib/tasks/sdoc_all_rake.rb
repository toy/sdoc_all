require 'sdoc_all'

task :default => :run

desc "Build/update documentation"
task :run do
  SdocAll.run
end

namespace :run do
  desc "Force update sources, before building/updating"
  task :force do
    SdocAll.run(:update => true)
  end
end
