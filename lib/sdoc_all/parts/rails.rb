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

      Base.add_task(
        :src_path => path,
        :doc_path => "rails-#{version}",
        :paths => get_paths(path),
        :title => "rails-#{version}"
      )
    end

    def get_paths(app_dir)
      code = %{
        require 'rubygems'
        require 'rake'
        require 'rake/rdoctask'

        Rake::RDocTask.class_eval{ def define; puts rdoc_files if name == 'rails'; end }

        class RDocTaskWithoutDescriptions < Rake::RDocTask
          def initialize(name = :rdoc); super; puts rdoc_files if name == 'rails'; end
        end

        Dir.chdir(ARGV.first){ load('Rakefile') }
      }.strip.gsub(/\s*\n\s*/m, '; ')
      args = 'ruby', '-e', code, app_dir.to_s
      IO.popen(args.shelljoin, &:readlines).map(&:strip)
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
