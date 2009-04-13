class RdocAll
  class Plugins < Base
    def self.each(&block)
      Dir['plugins/*'].each(&block)
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
          add_rdoc_task(
            :name_parts => [File.basename(plugin)],
            :src_path => plugin,
            :doc_path => plugin,
            :pathes => pathes.resolve
          )
        end
      end
    end
  end
end
