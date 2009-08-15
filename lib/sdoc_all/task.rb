require 'digest'

class SdocAll
  class Task
    attr_reader :src_path, :doc_path, :paths, :main, :title, :index
    def initialize(options = {})
      options[:paths] ||= []
      [/^readme$/i, /^readme\.(?:txt|rdoc|markdown)$/i, /^readme\./i].each do |readme_r|
        options[:main] ||= options[:paths].grep(readme_r).first
      end

      @src_path = Pathname.new(options[:src_path]).expand_path
      @doc_path = options[:doc_path]
      @paths = options[:paths]
      @main = options[:main]
      @title = options[:title]
      @index = options[:index]
    end

    def run(options = {})
      if clobber?
        Base.remove_if_present(Base.docs_path + doc_path)

        cmd = %w(sdoc)
        cmd << '-o' << Base.docs_path + doc_path
        cmd << '-t' << title
        cmd << '-T' << 'direct'

        if src_path.directory?
          Dir.chdir(src_path) do
            cmd << '-m' << main if main
            Base.system(*cmd + paths)
          end
          if index
            custom_index_dir_name = 'custom_index'
            custom_index_path = Base.docs_path + doc_path + custom_index_dir_name
            Base.remove_if_present(custom_index_path)
            FileUtils.cp_r(index, custom_index_path)
            index_html = Base.docs_path + doc_path + 'index.html'
            index_html.write index_html.read.sub(/(<frame src=")[^"]+(" name="docwin" \/>)/, "\\1#{custom_index_dir_name}/index.html\\2")
          end
        else
          Base.system(*cmd + [src_path])
        end

        if (Base.docs_path + doc_path).directory?
          config_hash_path.open('w') do |f|
            f.write(hash)
          end
        end
      end
    end

    def hash
      for_hash = [src_path.to_s, doc_path.to_s, paths, main, title, last_build_time]
      for_hash << index if index
      Digest::SHA1.hexdigest(for_hash.inspect)
    end

    def config_hash_path
      Base.docs_path + doc_path + 'config.hash'
    end

    def created_rid_path
      Base.docs_path + doc_path + 'created.rid'
    end

    def last_build_time
      Time.parse(created_rid_path.read) rescue nil
    end

    def clobber?
      full_doc_path = Base.docs_path + doc_path
      return true unless full_doc_path.exist?

      created_hash = config_hash_path.read rescue nil
      return true if created_hash != hash

      latest = [src_path.mtime, src_path.ctime].max
      created = last_build_time
      if created && latest < created
        src_path.find do |path|
          Find.prune if path.directory? && path.basename.to_s[0] == ?.
          latest = [latest, path.mtime, path.ctime].max
          break unless latest < created
        end
      end
      created.nil? || latest >= created
    end
  end
end
