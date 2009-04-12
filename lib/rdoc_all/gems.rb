class RdocAll
  class Gems < Base
    def self.each(&block)
      Gem.source_index.each(&block)
    end

    def self.update_sources(options = {})
    end

    def self.add_rdoc_tasks
      each do |gem_name, spec|
        add_rdoc_task([spec.name, spec.version], 'gems' / gem_name, spec.require_paths + spec.extra_rdoc_files)
      end
    end
  end
end
