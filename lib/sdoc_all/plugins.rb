class SdocAll
  class Plugins < Base
    def self.each(&block)
      Dir[File.expand_path('~/.plugins/*')].each(&block)
    end

    def self.update_sources(options = {})
      each do |plugin|
        Dir.chdir(plugin) do
          system('git fetch origin && git reset --hard HEAD')
        end
      end
    end

    def self.add_rdoc_tasks
      each do |plugin|
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
