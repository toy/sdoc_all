task :default => :update

desc "Update documentation"
task :update do
  require 'sdoc_all'

  options = YAML.load_file('sdoc.config.yml').symbolize_keys rescue {}

  SdocAll.run(options)
end
