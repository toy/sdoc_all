class SdocAll
  class Rails < Base
    def initialize(raw_config)
      raw_config ||= {}
      raw_config = {:version => raw_config} unless raw_config.is_a?(Hash)

      if raw_config[:version]
        unless self.class.versions.include?(raw_config[:version])
          raise ConfigError.new("you don't have rails #{raw_config[:version]} installed")
        end
      else
        if self.class.versions.empty?
          raise ConfigError.new("you don't have any rails versions installed")
        end
      end

      @config = {
        :version => raw_config.delete(:version) || self.class.versions.last,
      }

      raise_unknown_options_if_not_blank!(raw_config)
    end

    def add_tasks(options = {})
      version = config[:version]
      path = sources_path + version

      unless path.directory?
        Base.remove_if_present(path)
        sources_path
        Base.with_env 'VERSION', version do
          Base.system('rails', path, '--freeze')
        end
      end
      self.class.used_sources << path

      paths = FileList.new
      Dir.chdir(path) do
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

    module ClassMethods
      def versions
        [].tap do |versions|
          Gem.source_index.search(Gem::Dependency.new('rails', :all)).each do |spec|
            versions << spec.version
          end
        end.sort.map(&:to_s)
      end
    end
    extend ClassMethods
  end
end
