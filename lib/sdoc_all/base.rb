class SdocAll
  class Base
    def self.inherited(subclass)
      (@subclasses ||= []) << subclass
    end

    def self.update_all_sources(options = {})
      FileUtils.mkdir_p(options[:sources_path]) unless File.directory?(options[:sources_path])
      Dir.chdir(options[:sources_path]) do
        @subclasses.each do |subclass|
          subclass.update_sources(options)
        end
      end
    end

    def self.rdoc_tasks(options = {})
      Dir.chdir(options[:sources_path]) do
        @@tasks = RdocTasks.new

        @subclasses.each do |subclass|
          subclass.add_rdoc_tasks
        end

        to_clear = Dir.glob(options[:docs_path] + '*/*')
        @@tasks.each do |task|
          doc_path = options[:docs_path] + task.doc_path
          to_clear.delete_if{ |path| path.starts_with?(doc_path) }
        end
        to_clear.each do |path|
          remove_if_present(path)
        end

        @@tasks.each do |task|
          doc_path = options[:docs_path] + task.doc_path

          begin
            raise 'force' if options[:force]
            if File.exist?(doc_path)
              unless File.directory?(doc_path)
                raise 'not a dir'
              else
                created = Time.parse(File.read(doc_path + 'created.rid'))
                Find.find(options[:sources_path] + task.src_path) do |path|
                  Find.prune if File.directory?(path) && File.basename(path)[0] == ?.
                  raise "changed #{path}" if File.ctime(path) > created || File.mtime(path) > created
                end
              end
            end
          rescue => e
            puts e
            remove_if_present(doc_path)
          end
        end

        @@tasks
      end
    end

  protected

    def self.add_rdoc_task(options = {})
      options[:pathes] ||= []
      [/^readme$/i, /^readme\.(?:txt|rdoc|markdown)$/i, /^readme\./i].each do |readme_r|
        options[:main] ||= options[:pathes].grep(readme_r).first
      end
      @@tasks.add(self, options)
    end

    def self.with_env(key, value)
      old_value, ENV[key] = ENV[key], value
      yield
    ensure
      ENV[key] = old_value
    end

    def self.remove_if_present(path)
      FileUtils.remove_entry(path) if File.exist?(path)
    end
  end
end
