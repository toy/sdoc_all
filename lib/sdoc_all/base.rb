require 'shell_escape'

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

      def dry_run!
        @@dry_run = true
      end
      def dry_run?
        defined?(@@dry_run) && @@dry_run
      end
      def verbose_level=(val)
        @@verbose_level = val
      end
      def verbose_level
        defined?(@@verbose_level) ? @@verbose_level : 0
      end

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

      def used_sources
        @used_sources ||= []
      end

      def inherited(subclass)
        subclasses[subclass.short_name] = subclass
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
        subclass = subclasses[type] || subclasses[type.singularize] || subclasses[type.pluralize]
        if subclass
          entries << subclass.new(config)
        else
          raise ConfigError.new("don't know how to build \"#{type}\" => #{config.inspect}")
        end
      end

      def tasks(options = {})
        @@tasks = []
        entries.with_progress('configuring').each do |entry|
          entry.add_tasks(options)
        end
        subclasses.values.each do |subclass|
          unless subclass.used_sources.empty?
            paths = FileList.new
            paths.include(subclass.sources_path + '*')
            subclass.used_sources.each do |path|
              paths.exclude(path)
            end
            paths.resolve.each do |path|
              remove_if_present(path)
            end
          end
        end
        @@tasks
      end

      def add_task(options = {})
        @@tasks << Task.new(options)
      end

      def add_merge_task(options = {})
        @@tasks << MergeTask.new(options)
      end

      def system(*args)
        command = args.length == 1 ? args.first : ShellEscape.command(*args)
        if verbose_level >= 1
          puts [dirs.last && "cd #{dirs.last}", command].compact.join('; ').shrink(250).blue
        end
        unless dry_run?
          if verbose_level >= 2
            Kernel.system(*args)
          else
            rd, wr = IO::pipe

            pid = fork{
              rd.close
              STDOUT.reopen(wr)
              STDERR.reopen(wr)
              wr.close
              exec(*args)
            }

            wr.close
            begin
              true while line = rd.gets
            ensure
              rd.close unless rd.closed?
              Process.wait(pid)
            end
          end
          unless $?.success?
            if $?.signaled?
              raise SignalException.new($?.termsig)
            else
              abort("failed: #{command}")
            end
          end
        end
      end

      def remove_if_present(path)
        path = Pathname(path)
        if path.exist?
          puts "rm -r #{ShellEscape.word(path)}".magenta
          FileUtils.remove_entry(path) unless dry_run?
        end
      end

      def dirs
        @@dirs ||= []
      end

      def chdir(path, &block)
        path = Pathname(path)
        dirs.push(path.expand_path)
        Dir.chdir(path, &block)
      ensure
        dirs.pop
      end

      def with_env(key, value)
        old_value, ENV[key] = ENV[key], value
        yield
      ensure
        ENV[key] = old_value
      end

      def output_for_verbose_level(n)
        if verbose_level >= n
          yield
        else
          old_stdout = $stdout
          old_stderr = $stderr
          dev_null = File.open('/dev/null', 'w')
          begin
            $stdout = dev_null
            $stderr = dev_null
            yield
          ensure
            $stdout = old_stdout
            $stderr = old_stderr
            dev_null.close
          end
        end
      end
    end
    extend ClassMethods
  end
end
