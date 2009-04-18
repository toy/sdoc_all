class SdocAll
  class Gems < Base
    def self.each(&block)
      Gem.source_index.each(&block)
    end

    def self.update_sources(options = {})
    end

    def self.add_rdoc_tasks
      each do |gem_name, spec|
        main = nil
        spec.rdoc_options.each_cons(2) do |options|
          main = options[1] if %w(--main -m).include?(options[0])
        end
        add_rdoc_task(
          :name_parts => [spec.name, spec.version],
          :src_path => spec.full_gem_path,
          :doc_path => 'gems' / gem_name,
          :pathes => spec.require_paths + spec.extra_rdoc_files,
          :main => main
        )
      end
    end
  end
end
