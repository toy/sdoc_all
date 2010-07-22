class SdocAll
  class Rails < Base
    def initialize(raw_config)
      raw_config ||= {}
      raw_config = {:version => raw_config} unless raw_config.is_a?(Hash)

      if raw_config[:version]
        if self.class.versions(raw_config[:version]).empty?
          raise ConfigError.new("you don't have rails #{raw_config[:version]} installed")
        end
      else
        if self.class.versions.empty?
          raise ConfigError.new("you don't have any rails versions installed")
        end
      end

      @config = {
        :version => self.class.versions(raw_config.delete(:version)).last,
      }

      raise_unknown_options_if_not_blank!(raw_config)
    end

    def add_tasks(options = {})
      version = config[:version]
      path = sources_path + "r#{version}"

      unless path.directory?
        Base.remove_if_present(path)
        sources_path
        Base.with_env 'VERSION', version.to_s do
          if version.to_s[/\d+/].to_i < 3
            Base.system('rails', "_#{version}_", path)
            Base.chdir(path) do
              Base.system('rake', 'rails:freeze:gems')
            end
          else
            Base.system('rails', "_#{version}_", 'new', path)
          end
        end
      end
      self.class.used_sources << path

      paths = FileList.new
      Base.chdir(path) do
        File.open('vendor/rails/railties/lib/tasks/documentation.rake') do |f|
          true until f.readline['Rake::RDocTask.new("rails")']
          until (line = f.readline.strip) == '}'
            if line['rdoc.rdoc_files.include']
              paths.include(line[/'(.*)'/, 1])
            elsif line['rdoc.rdoc_files.exclude']
              paths.exclude(line[/'(.*)'/, 1])
            end
          end
        end
        paths.resolve
      end
      Base.add_task(
        :src_path => path,
        :doc_path => "rails-#{version}",
        :paths => paths.to_a,
        :title => "rails-#{version}"
      )
    end

    class << self
      def versions(version_string = nil)
        [].tap do |versions|
          Gem.source_index.search(Gem::Dependency.new('rails', version_string)).each do |spec|
            versions << spec.version
          end
        end.sort
      end
    end
  end
end
