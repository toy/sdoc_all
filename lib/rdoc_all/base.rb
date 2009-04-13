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
          doc_path = DOCS_PATH / task.base_path
          remove_if_present(doc_path) if Dir[doc_path / '*'].empty? || options[:force]
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
