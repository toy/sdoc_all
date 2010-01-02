require 'net/ftp'
require 'net/http'

class SdocAll
  class Ruby < Base
    def initialize(raw_config)
      raw_config ||= {}
      raw_config = {:version => raw_config} unless raw_config.is_a?(Hash)

      @config = {
        :update => raw_config.delete(:update) != false,
        :version => raw_config.delete(:version).to_s,
        :index => raw_config.delete(:index),
        :stdlib => raw_config.delete(:stdlib),
      }

      unless config[:version].present?
        raise ConfigError.new("specify version of ruby (place archive to 'sources' directory or it will be download from ftp://ftp.ruby-lang.org/)")
      end

      if binary = config[:version][/^`(.*)`$/, 1]
        version = `#{binary} -e 'print "\#{RUBY_VERSION}-p\#{RUBY_PATCHLEVEL}"'`
        if $?.success? && version[/^\d+\.\d+\.\d+-p\d+$/]
          config[:version] = version
        else
          raise ConfigError.new("binary `#{binary}` failed or does not seem to be ruby binary as version returned is #{version.inspect}")
        end
      end

      self.class.find_or_download_matching_archive(config[:version])

      if config[:index]
        index = Pathname(config[:index])
        unless index.directory? && (index + 'index.html').file?
          raise ConfigError.new("index should be a directory with index.html inside and all related files should be with relative links")
        end
      end

      if config[:stdlib]
        download_and_get_stdlib_config
      end

      raise_unknown_options_if_not_blank!(raw_config)
    end

    def add_tasks(options = {})
      archive = self.class.find_or_download_matching_archive(config[:version], :update => config[:update] && options[:update])
      version = archive.full_version
      src_path = sources_path + version

      unless src_path.directory?
        Base.remove_if_present(src_path)
        case archive.extension
        when 'tar.bz2'
          Base.system('tar', '-xjf', archive.path, '-C', sources_path)
        when 'tar.gz'
          Base.system('tar', '-xzf', archive.path, '-C', sources_path)
        when 'zip'
          Base.system('unzip', '-q', archive.path, '-d', sources_path)
        end
        File.rename(sources_path + "ruby-#{version}", src_path)
      end
      self.class.used_sources << src_path

      if config[:stdlib] == 'integrate'
        stdlib_config = download_and_get_stdlib_config(:update => config[:update] && options[:update])
        paths = FileList.new
        Base.chdir(src_path) do
          paths.add(get_ruby_files_to_document)
          stdlib_config['targets'].each do |target|
            name = target['target']
            paths.add(get_stdlib_files_to_document(name))
          end
          paths.resolve
        end
        task_options = {
          :src_path => src_path,
          :doc_path => "ruby-#{version}_with_stdlib",
          :title => "ruby-#{version} +stdlib",
          :paths => paths.to_a
        }
        task_options[:index] = config[:index] if config[:index]
        Base.add_task(task_options)
      else
        task_options = {
          :src_path => src_path,
          :doc_path => "ruby-#{version}",
          :title => "ruby-#{version}"
        }
        task_options[:index] = config[:index] if config[:index]
        Base.add_task(task_options)

        if config[:stdlib]
          stdlib_config = download_and_get_stdlib_config(:update => config[:update] && options[:update])

          stdlib_tasks = []
          Base.chdir(src_path) do
            main_files_to_document = get_ruby_files_to_document
            stdlib_config['targets'].each do |target|
              name = target['target']

              paths = get_stdlib_files_to_document(name)

              if paths.present? && (paths - main_files_to_document).present?
                stdlib_tasks << {
                  :src_path => src_path,
                  :doc_path => name.gsub(/[^a-z0-9\-_]/i, '-'),
                  :paths => paths.to_a,
                  :main => target['mainpage'],
                  :title => name
                }
              end
            end
          end
          Base.add_merge_task(
            :doc_path => "ruby-stdlib-#{version}",
            :title => "ruby-stdlib-#{version}",
            :tasks_options => stdlib_tasks.sort_by{ |task| task[:title].downcase }
          )
        end
      end
    end

  private

    def get_ruby_files_to_document(dir = nil)
      files = []

      dot_document_name = '.document'
      dot_document_path = dir ? dir + dot_document_name : Pathname(dot_document_name)
      if dot_document_path.exist?
        dot_document_path.readlines.map(&:strip).reject(&:blank?).reject{ |line| line[/^\s*#/] }
      else
        ['*']
      end.each do |glob|
        Pathname.glob(dir ? dir + glob : glob) do |path|
          if path.directory?
            files.concat(get_ruby_files_to_document(path))
          else
            files << path.to_s
          end
        end
      end

      files
    end

    def get_stdlib_files_to_document(name)
      paths = FileList.new
      paths.include("{lib,ext}/#{name}/**/README*")
      paths.include("{lib,ext}/#{name}.{c,rb}")
      paths.include("{lib,ext}/#{name}/**/*.{c,rb}")
      paths.resolve
      paths.reject! do |path|
        [%r{/extconf.rb\Z}, %r{/test/(?!unit)}, %r{/tests/}, %r{/sample}, %r{/demo/}].any?{ |pat| pat.match path }
      end
      paths
    end

    def download_and_get_stdlib_config(options = {})
      stdlib_config_url = 'http://stdlib-doc.rubyforge.org/svn/trunk/data/gendoc.yaml'
      if options[:update] || (config = get_stdlib_config).nil?
        data = Net::HTTP.get(URI.parse(stdlib_config_url))
        stdlib_config_path.write(data)
        if (config = get_stdlib_config).nil?
          raise ConfigError.new("could not get stdlib config from #{stdlib_config_url}")
        end
      end
      config
    end

    def get_stdlib_config
      YAML.load_file stdlib_config_path if stdlib_config_path.readable?
    end

    def stdlib_config_path
      sources_path.parent + 'stdlib-gendoc.yaml'
    end

    ArchiveInfo = Struct.new(:path, :name, :full_version, :extension, :version)
    class << self
      def match_ruby_archive(path)
        name = File.basename(path)
        if match = /^ruby-((\d+\.\d+\.\d+)-p(\d+))(?:\.(tar\.(?:gz|bz2)|zip))$/.match(name)
          ArchiveInfo.new.tap do |i|
            i.path = path
            i.name = name
            i.full_version = match[1]
            i.extension = match[4]
            i.version = match[2].split('.').map(&:to_i) << match[3].to_i
          end
        end
      end

      def last_matching_ruby_archive(version, paths)
        paths.map do |path|
          match_ruby_archive(path)
        end.compact.sort_by(&:version).reverse.find do |tar_info|
          tar_info.full_version.starts_with?(version)
        end
      end

      def find_matching_archive(version)
        paths = sources_path.parent.children.select(&:file?)
        last_matching_ruby_archive(version, paths)
      end

      def download_matching_archive(version)
        Progress.start("downloading ruby #{version}") do
          output_for_verbose_level(2) do
            Net::FTP.open('ftp.ruby-lang.org') do |ftp|
              remote_path = Pathname('/pub/ruby')
              ftp.debug_mode = true
              ftp.passive = true
              ftp.login
              ftp.chdir(remote_path)

              tar = nil

              dirs, files = [], []
              ftp.list('*').map do |line|
                full_path = remote_path + line.split.last
                (line.starts_with?('d') ? dirs : files) << full_path
              end

              tar_bz2_matcher = /(^|\/)ruby-.*\.tar\.bz2$/

              unless tar = last_matching_ruby_archive(version, files.select{ |file| tar_bz2_matcher === file.to_s }) || last_matching_ruby_archive(version, files)
                dirs = dirs.sort_by{ |dir| s = dir.basename.to_s; v = s.to_f; [v, s] }.reverse.
                            select{ |dir| dir.basename.to_s[/^\d/] && dir.basename.to_s.starts_with?(version[0, 3]) }
                dirs.each do |dir|
                  files = ftp.nlst(dir)
                  break if tar = last_matching_ruby_archive(version, files.grep(tar_bz2_matcher)) || last_matching_ruby_archive(version, files)
                end
              end

              if tar
                dest = sources_path.parent + tar.name
                unless dest.exist? && dest.size == ftp.size(tar.path)
                  ftp.getbinaryfile(tar.path, dest)
                end
              end
            end
          end
        end
      end

      def find_or_download_matching_archive(version, options = {})
        if options[:update] || (archive = find_matching_archive(version)).nil?
          download_matching_archive(version)
          if (archive = find_matching_archive(version)).nil?
            raise ConfigError.new("could not find version of ruby matching #{version.inspect}")
          end
        end
        archive
      end
    end
  end
end
