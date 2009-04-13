class RdocAll
  class Base
    def self.inherited(subclass)
      (@subclasses ||= []) << subclass
    end

    def self.update_all_sources(options = {})
      Dir.chdir(SOURSES_PATH) do
        @subclasses.each do |subclass|
          subclass.update_sources(options)
        end
      end
    end

    def self.rdoc_tasks(options = {})
      Dir.chdir(SOURSES_PATH) do
        @@tasks = RdocTasks.new

        @subclasses.each do |subclass|
          subclass.add_rdoc_tasks
        end

        to_clear = Dir.glob(DOCS_PATH / '*' / '*')
        @@tasks.each do |task|
          doc_path = DOCS_PATH / task.doc_path
          to_clear.delete_if{ |path| path.starts_with?(doc_path) }
        end
        to_clear.each do |path|
          remove_if_present(path)
        end

        @@tasks.each do |task|
          doc_path = DOCS_PATH / task.doc_path

          begin
            raise 'force' if options[:force]
            if File.exist?(doc_path)
              unless File.directory?(doc_path)
                raise 'not a dir' 
              else
                created = Time.parse(File.read(doc_path / 'created.rid'))
                Find.find(SOURSES_PATH / task.src_path) do |path|
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
  end
end
