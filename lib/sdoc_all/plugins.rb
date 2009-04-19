class SdocAll
  class Plugins < Base
    def self.each(plugins_path, &block)
      Dir[plugins_path + '*'].each(&block)
    end

    def self.update_sources(options = {})
      each(options[:plugins_path]) do |plugin|
        Dir.chdir(plugin) do
          system('git fetch origin && git reset --hard HEAD')
        end
      end
    end

    def self.add_rdoc_tasks(options = {})
      each(options[:plugins_path]) do |plugin|
        Dir.chdir(plugin) do
          pathes = Rake::FileList.new
          pathes.include('lib/**/*.rb')
          pathes.include('README*')
          pathes.include('CHANGELOG*')
          plugin_name = File.basename(plugin)
          add_rdoc_task(
            :name_parts => [plugin_name],
            :src_path => plugin,
            :doc_path => "plugins/#{plugin_name}",
            :pathes => pathes.resolve
          )
        end
      end
    end
  end
end
