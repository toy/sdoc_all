class RdocAll::Base
  class << self
    def inherited(subclass)
      (@subclasses ||= []) << subclass
    end

    def update_all_sources(options = {})
      Dir.chdir(SOURSES_PATH) do
        @subclasses.each do |subclass|
          subclass.update_sources(options)
        end
      end
    end

    def rdoc_tasks(options = {})
      Dir.chdir(SOURSES_PATH) do
        @@rdoc_tasks = []

        @subclasses.each do |subclass|
          subclass.add_rdoc_tasks
        end

        to_clear = Dir.glob(DOCS_PATH / '*' / '*')
        @@rdoc_tasks.each do |rdoc_task|
          doc_path = DOCS_PATH / rdoc_task[:base_path]
          to_clear.delete_if{ |path| path[0, doc_path.length] == doc_path }
        end
        to_clear.each do |path|
          remove_if_present(path)
        end

        @@rdoc_tasks.each do |rdoc_task|
          doc_path = DOCS_PATH / rdoc_task[:base_path]
          remove_if_present(doc_path) if Dir[doc_path / '*'].empty? || options[:force]
        end

        @@rdoc_tasks
      end
    end

  protected

    def add_rdoc_task(base_path, source_pathes = [])
      @@rdoc_tasks << {:base_path => base_path, :source_pathes => source_pathes, :title => base_path.sub('s/', ' — ')}
    end

    def with_env(key, value)
      old_value, ENV[key] = ENV[key], value
      yield
    ensure
      ENV[key] = old_value
    end

    def remove_if_present(path)
      FileUtils.remove_entry(path) if File.exist?(path)
    end
  end
end
