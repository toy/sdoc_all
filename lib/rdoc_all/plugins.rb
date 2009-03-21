class RdocAll::Plugins < RdocAll::Base
  class << self
    def each(&block)
      Dir['plugins/*'].each(&block)
    end

    def update_sources(options = {})
      each do |plugin|
        Dir.chdir(plugin) do
          system('git fetch origin && git reset --hard HEAD')
        end
      end
    end

    def add_rdoc_tasks
      each do |plugin|
        Dir.chdir(plugin) do
          pathes = Rake::FileList.new
          pathes.include('lib/**/*.rb')
          pathes.include('README*')
          pathes.include('CHANGELOG*')
          add_rdoc_task(plugin, pathes.resolve)
        end
      end
    end
  end
end
