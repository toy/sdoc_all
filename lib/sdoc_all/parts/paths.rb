class SdocAll
  class Paths < Base
    def initialize(raw_config)
      raw_config = [raw_config] unless raw_config.is_a?(Array)

      errors = []
      raw_config.each do |raw_entry|
        begin
          raw_entries = case raw_entry
          when Hash
            [raw_entry]
          when String
            Dir[File.expand_path(raw_entry)].map{ |path| {:root => path} }
          else
            raise_unknown_options_if_not_blank!(raw_entry)
          end

          raw_entries.each do |entry|
            begin
              entry.symbolize_keys!

              unless entry[:root].present?
                raise ConfigError.new("specify what to document")
              end

              root = Pathname.new(entry.delete(:root)).expand_path

              unless root.exist?
                raise ConfigError.new("path #{root} does not exist")
              end

              paths = entry.delete(:paths)
              paths = [paths] if paths && !paths.is_a?(Array)

              entries << {
                :root => root,
                :main => entry.delete(:main),
                :paths => paths,
              }
              raise_unknown_options_if_not_blank!(entry)
            rescue ConfigError => e
              errors << e
            end
          end
        rescue ConfigError => e
          errors << e
        end
      end
      unless errors.empty?
        raise ConfigError.new(errors.join("\n"))
      end
    end

    def add_tasks(options = {})
      common_path = self.class.common_path(entries.map{ |entry| entry[:root] })

      entries.each do |entry|
        path = entry[:root]

        task_options = {
          :src_path => path,
          :doc_path => "paths.#{path.relative_path_from(common_path).to_s.gsub('/', '.')}",
          :title => "paths: #{path.relative_path_from(common_path)}"
        }
        task_options[:main] = entry[:main] if entry[:main]

        if entry[:paths]
          paths = FileList.new
          Base.chdir(path) do
            entry[:paths].each do |glob|
              m = /^([+-]?)(.*)$/.match(glob)
              if m[1] == '-'
                paths.exclude(m[2])
              else
                paths.include(m[2])
              end
            end
            paths.resolve
          end

          task_options[:paths] = paths.to_a
        end

        Base.add_task(task_options)
      end
    end

  private

    def entries
      @entries ||= []
    end

    module ClassMethods
      def common_path(paths)
        common = nil
        paths.each do |path|
          if common ||= path
            unless path.to_s.starts_with?(common.to_s)
              path.ascend do |path_part|
                if common.to_s.starts_with?(path_part)
                  common = path_part
                  break
                end
              end
            end
          end
        end
        common = common.parent if common
      end
    end
    extend ClassMethods
  end
end
