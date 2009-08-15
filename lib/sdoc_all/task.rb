require 'digest'

class SdocAll
  class BaseTask
    def config_hash
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
      return true if created_hash != config_hash
    end
  end

  class Task < BaseTask
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
            f.write(config_hash)
          end
        end
      end
    end

    def for_hash
      for_hash = [src_path.to_s, doc_path.to_s, paths, main, title, last_build_time]
      for_hash << index if index
      for_hash
    end

    def clobber?
      return true if super

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

    def occupied_doc_pathes
      [doc_path]
    end
  end

  class MergeTask < BaseTask
    attr_reader :doc_path, :title, :tasks, :titles
    def initialize(options = {})
      @doc_path = options[:doc_path]
      @title = options[:title]
      @tasks = options[:tasks_options].map do |task_options|
        Task.new(task_options.merge(
          :doc_path => "#{parts_path}/#{task_options[:doc_path]}",
          :title => "#{title}: #{task_options[:title]}"
        ))
      end
      @titles = options[:tasks_options].map do |task_options|
        task_options[:title]
      end
    end

    def parts_path
      "#{doc_path}_parts"
    end

    def run(options = {})
      p clobber?
      if clobber?
        Base.remove_if_present(Base.docs_path + doc_path)

        tasks.each do |task|
          task.run(options)
        end

        Dir.chdir(Base.docs_path) do
          cmd = %w(sdoc-merge)
          cmd << '-o' << Base.docs_path + doc_path
          cmd << '-t' << title
          cmd << '-n' << titles.join(',')
          cmd << '-u' << tasks.map{ |task| "../#{task.doc_path}" }.join(' ')
          Base.system(*cmd + tasks.map(&:doc_path))
        end
      end
    end

    def for_hash
      [doc_path.to_s, title, tasks.map(&:config_hash).join(' ')]
    end

    def clobber?
      return true if super

      tasks.any?(&:clobber?)
    end

    def occupied_doc_pathes
      [doc_path, parts_path]
    end
  end
end
