class SdocAll
  class Gems < Base
    def initialize(raw_config)
      raw_config ||= {}
      raw_config = {:only => raw_config} unless raw_config.is_a?(Hash)

      @config = {
        :versions => raw_config.delete(:versions).to_s.downcase,
        :only => config_only_option(raw_config),
        :exclude => config_exclude_option(raw_config),
      }

      errors = []
      gem_names = unfiltered_specs.map{ |spec| spec.name.downcase }
      [:only, :exclude].each do |option|
        if config[option]
          config[option].each do |gem_name|
            errors << "#{option} #{gem_name} does not match any gem" unless gem_names.include?(gem_name)
          end
        end
      end
      unless errors.empty?
        raise ConfigError.new(errors.join("\n"))
      end

      if filtered_specs.empty?
        options = config.map do |option, values|
          "#{option} => #{Array(values).join(',')}" if values.present?
        end.compact.join(', ')
        raise ConfigError.new("no gems matches #{options}")
      end

      raise_unknown_options_if_not_blank!(raw_config)
    end

    def add_tasks(options = {})
      specs = filtered_specs.sort_by{ |spec| [spec.name.downcase, spec.sort_obj] }
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

  private

    def unfiltered_specs
      config[:versions] == 'all' ? self.class.all_specs : self.class.latest_specs
    end

    def filtered_specs
      specs = unfiltered_specs

      specs.delete_if{ |spec| !config[:only].include?(spec.name.downcase) } if config[:only]
      specs.delete_if{ |spec| config[:exclude].include?(spec.name.downcase) }

      specs
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
