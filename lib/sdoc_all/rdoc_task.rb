class SdocAll
  class RdocTask
    def initialize(options = {})
      @options = options
      @options[:title] = @options[:doc_path].sub('s/', ' — ') if @options[:doc_path]
    end

    def src_path
      @options[:src_path]
    end

    def doc_path
      @options[:doc_path]
    end

    def pathes
      @options[:pathes]
    end

    def title
      @options[:title]
    end

    def main
      @options[:main]
    end

    def name_parts
      @options[:name_parts]
    end

    def run(options = {})
      unless File.directory?(options[:docs_path] + doc_path)
        Dir.chdir(options[:sources_path] + src_path) do
          cmd = %w(sdoc)
          cmd << '-o' << options[:docs_path] + doc_path
          cmd << '-t' << title
          cmd << '-T' << 'direct'
          cmd << '-m' << main if main
          system(*cmd + pathes)
        end
      end
    end
  end
end
