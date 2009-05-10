require 'net/ftp'

class SdocAll
  class Ruby < Base
    def initialize(config)
      config ||= {}
      config = {:version => config} unless config.is_a?(Hash)

      @config = {
        :update => config.delete(:update) != false,
        :version => config.delete(:version),
      }

      version = @config[:version]
      unless version.present?
        raise ConfigError.new("specify version of ruby (place archive to 'sources' directory or it will be download from ftp://ftp.ruby-lang.org/)")
      end
      self.class.find_or_download_matching_archive(version)

      raise_unknown_options_if_not_blank!(config)
    end

    def add_tasks(options = {})
      archive = self.class.find_or_download_matching_archive(config[:version], :update => config[:update] && options[:update])
      version = archive.full_version
      path = sources_path + version

      unless path.directory?
        Base.remove_if_present(path)
        case archive.extension
        when 'tar.bz2'
          Base.system('tar', '-xjf', archive.path, '-C', sources_path)
        when 'tar.gz'
          Base.system('tar', '-xzf', archive.path, '-C', sources_path)
        when 'zip'
          Base.system('unzip', '-q', archive.path, '-d', sources_path)
        end
        File.rename(sources_path + "ruby-#{version}", path)
      end
      self.class.used_sources << path

      Base.add_task(
        :src_path => path,
        :doc_path => "ruby-#{version}",
        :title => "ruby-#{version}"
      )
    end

  private

    ArchiveInfo = Struct.new(:path, :name, :full_version, :extension, :version)
    module ClassMethods
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
        Net::FTP.open('ftp.ruby-lang.org') do |ftp|
          remote_path = '/pub/ruby'
          ftp.debug_mode = true
          ftp.passive = true
          ftp.login
          ftp.chdir(remote_path)
          paths = ftp.list('ruby-*.tar.bz2').map{ |line| "#{remote_path}/#{line.split.last}" }

          if tar = last_matching_ruby_archive(version, paths)
            dest = sources_path.parent + tar.name
            unless File.exist?(dest) && File.size(dest) == ftp.size(tar.path)
              ftp.getbinaryfile(tar.path, dest)
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
    extend ClassMethods
  end
end
