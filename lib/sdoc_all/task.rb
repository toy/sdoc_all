require 'digest'

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
      Digest::SHA1.hexdigest([src_path.to_s, doc_path.to_s, paths, main, title, last_build_time].inspect)
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
