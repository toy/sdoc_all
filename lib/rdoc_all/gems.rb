class RdocAll::Gems < RdocAll::Base
  class << self
    def each(&block)
      Gem.source_index.each(&block)
    end

    def update_sources(options = {})
    end

    def add_rdoc_tasks
      each do |gem_name, spec|
        add_rdoc_task('gems' / gem_name, spec.require_paths + spec.extra_rdoc_files)
      end
    end
  end
end
