task :default => :update

desc "Update documentation"
task :update do
  require 'sdoc_all'
  SdocAll.update_sources
  SdocAll.build_documentation
end
