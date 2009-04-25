class SdocAll
  class Base
    attr_reader :config

  protected

    def raise_unknown_options_if_not_blank!(config)
      unless config.blank?
        raise ConfigError.new("unknown options for \"#{self.class.short_name}\": #{config.inspect}")
      end
    end

    def config_only_option(config)
      if only = config.delete(:only)
        [only].flatten.map(&:to_s).map(&:downcase)
      end
    end

    def config_exclude_option(config)
      if exclude = config.delete(:exclude)
        [exclude].flatten.map(&:to_s).map(&:downcase)
      else
        []
      end
    end

    def sources_path
      self.class.sources_path
    end

    module ClassMethods
      BASE_PATH = Pathname.new(Dir.pwd).expand_path
      DOCS_PATH = BASE_PATH + 'docs'
      PUBLIC_PATH = BASE_PATH + 'public'

      def base_path
        BASE_PATH
      end

      def docs_path
        DOCS_PATH.tap(&:mkpath)
      end

      def public_path
        PUBLIC_PATH
      end

      def subclasses
        @subclasses ||= {}
      end

      def short_name
        name.demodulize.underscore
      end

      def sources_path
        Pathname.new("sources/#{short_name}").tap do |path|
          path.mkpath
        end
      end

      def inherited(subclass)
        name = subclass.short_name
        [name, name.singularize, name.pluralize].uniq.each do |name_form|
          subclasses[name_form] = subclass
        end
      end

      def entries
        @entries ||= []
      end

      def clear
        entries.clear
      end

      def to_document(type, config)
        type = type.to_s
        config.symbolize_keys! if config.is_a?(Hash)
        if subclasses[type]
          entries << subclasses[type].new(config)
        else
          raise ConfigError.new("don't know how to build \"#{type}\" => #{config.inspect}")
        end
      end

      def tasks(options = {})
        @@tasks = []
        entries.each do |entry|
          entry.add_tasks(options)
        end
        @@tasks
      end

      def add_task(options = {})
        options[:paths] ||= []
        [/^readme$/i, /^readme\.(?:txt|rdoc|markdown)$/i, /^readme\./i].each do |readme_r|
          options[:main] ||= options[:paths].grep(readme_r).first
        end
        @@tasks << Task.new(options)
      end

      def system(*args)
        escaped_args = args.map(&:to_s).map{ |arg| arg[/[^a-z0-9\/\-.]/i] ? arg.inspect : arg }
        command = escaped_args.join(' ')
        puts "Executing #{command.length > 250 ? "#{command[0, 247]}..." : command}"
        Kernel.system(*args)
      end

      def remove_if_present(path)
        FileUtils.remove_entry(path) if File.exist?(path)
      end

      def with_env(key, value)
        old_value, ENV[key] = ENV[key], value
        yield
      ensure
        ENV[key] = old_value
      end
    end
    extend ClassMethods
  end
end
