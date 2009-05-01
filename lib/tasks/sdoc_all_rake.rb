require 'sdoc_all'

task :default => :run

desc "Build/update documentation"
task :run do
  SdocAll.run
end

desc "Clobber documentation"
task :clobber do
  rm_rf 'docs' rescue nil
  rm_rf 'public' rescue nil
end

namespace :run do
  desc "Force update sources, before building/updating"
  task :update do
    SdocAll.run(:update => true)
  end
end
