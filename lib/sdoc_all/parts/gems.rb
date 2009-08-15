class SdocAll
  class Gems < Base
    def initialize(config)
      config ||= {}
      config = {:only => config} unless config.is_a?(Hash)

      @config = {
        :versions => config.delete(:versions).to_s.downcase,
        :only => config_only_option(config),
        :exclude => config_exclude_option(config),
      }

      raise_unknown_options_if_not_blank!(config)
    end

    def add_tasks(options = {})
      specs = config[:versions] == 'all' ? self.class.all_specs : self.class.latest_specs

      specs.sort_by!{ |spec| [spec.name.downcase, spec.sort_obj] }

      specs.delete_if{ |spec| !config[:only].include?(spec.name.downcase) } if config[:only]
      specs.delete_if{ |spec| config[:exclude].include?(spec.name.downcase) }

      specs.each do |spec|
        main = nil
        spec.rdoc_options.each_cons(2) do |options|
          main = options[1] if %w(--main -m).include?(options[0])
        end
        Base.add_task(
          :src_path => spec.full_gem_path,
          :doc_path => "gems.#{spec.full_name}",
          :paths => spec.require_paths + spec.extra_rdoc_files,
          :main => main,
          :title => "gems: #{spec.full_name}"
        )
      end
    end

    module ClassMethods
      def latest_specs
        Gem.source_index.latest_specs
      end

      def all_specs
        specs = []
        Gem.source_index.each do |_, spec|
          specs << spec
        end
        specs
      end
    end
    extend ClassMethods
  end
end
