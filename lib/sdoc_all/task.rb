class SdocAll
  class Task
    attr_reader :src_path, :doc_path, :paths, :main, :title
    def initialize(options = {})
      @src_path = Pathname.new(options[:src_path]).expand_path
      @doc_path = options[:doc_path]
      @paths = options[:paths]
      @main = options[:main]
      @title = options[:title]
    end

    def run(options = {})
      cmd = %w(sdoc)
      cmd << '-o' << Base.docs_path + doc_path
      cmd << '-t' << title
      cmd << '-T' << 'direct'

      if src_path.directory?
        Dir.chdir(src_path) do
          cmd << '-m' << main if main
          Base.system(*cmd + paths)
        end
      else
        Base.system(*cmd + [src_path])
      end
    end
  end
end
