class SdocAll
  class Plugins < Base
    def initialize(config)
      config ||= {}
      config = {:path => config} unless config.is_a?(Hash)

      config[:path] ||= sources_path

      @config = {
        :update => config.delete(:update) != false,
        :path => Pathname.new(config.delete(:path)).expand_path,
        :only => config_only_option(config),
        :exclude => config_exclude_option(config),
      }

      unless @config[:path].directory?
        raise ConfigError.new("path #{@config[:path]} is not a directory")
      end

      raise_unknown_options_if_not_blank!(config)
    end

    def add_tasks(options = {})
      plugins = @config[:path].children.map do |path|
        path if path.directory?
      end.compact

      plugins.delete_if{ |plugin| !config[:only].include?(plugin.basename.to_s.downcase) } if config[:only]
      plugins.delete_if{ |plugin| config[:exclude].include?(plugin.basename.to_s.downcase) }

      if config[:update] && options[:update]
        plugins.each do |plugin|
          if (plugin + '.git').directory?
            Dir.chdir(plugin) do
              Base.system('git fetch origin && git reset --hard origin')
            end
          end
        end
      end

      plugins.each do |plugin|
        paths = Rake::FileList.new
        Dir.chdir(plugin) do
          paths.include('lib/**/*.rb')
          paths.include('README*')
          paths.include('CHANGELOG*')
          paths.resolve
        end
        Base.add_task(
          :src_path => plugin,
          :doc_path => "plugins.#{plugin.basename}",
          :paths => paths.to_a,
          :title => "plugins: #{plugin.basename}"
        )
      end
    end
  end
end
