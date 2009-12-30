class SdocAll
  class Plugins < Base
    def initialize(raw_config)
      raw_config ||= {}
      raw_config = {:path => raw_config} unless raw_config.is_a?(Hash)

      raw_config[:path] ||= sources_path

      @config = {
        :update => raw_config.delete(:update) != false,
        :path => Pathname.new(raw_config.delete(:path)).expand_path,
        :only => config_only_option(raw_config),
        :exclude => config_exclude_option(raw_config),
      }

      unless config[:path].directory?
        raise ConfigError.new("path #{config[:path]} is not a directory")
      end

      raise_unknown_options_if_not_blank!(raw_config)
    end

    def add_tasks(options = {})
      plugins = config[:path].children.select(&:directory?)

      plugins.delete_if{ |plugin| !config[:only].include?(plugin.basename.to_s.downcase) } if config[:only]
      plugins.delete_if{ |plugin| config[:exclude].include?(plugin.basename.to_s.downcase) }

      if config[:update] && options[:update]
        plugins.each do |plugin|
          if (plugin + '.git').directory?
            Base.chdir(plugin) do
              Base.system('git fetch origin && git reset --hard origin')
            end
          end
        end
      end

      plugins.each do |plugin|
        paths = FileList.new
        Base.chdir(plugin) do
          paths.include('lib/**/*.rb')
          paths.include('README*')
          paths.include('CHANGELOG*')

          begin
            File.open('Rakefile') do |f|
              true until f.readline['Rake::RDocTask']
              until ['end', '}'].include?(line = f.readline.strip)
                globs = line.scan(/'([^']*)'/).map{ |match| match[0] }
                if line['include(']
                  paths.include(*globs)
                elsif line['exclude(']
                  paths.exclude(*globs)
                end
              end
            end
          rescue
          end

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
