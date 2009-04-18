require 'net/ftp'

class SdocAll
  class Ruby < Base
    def self.tars
      Dir['ruby-*.tar.bz2']
    end

    def self.rubys
      Dir['ruby-*'].select{ |path| File.directory?(path) }
    end

    def self.update_sources(options = {})
      to_clear = tars
      Net::FTP.open('ftp.ruby-lang.org') do |ftp|
        remote_path = Pathname.new('/pub/ruby')
        ftp.debug_mode = true
        ftp.passive = true
        ftp.login
        ftp.chdir(remote_path)
        ftp.list('ruby-*.tar.bz2').each do |line|
          tar_path, tar = File.split(line.split.last)
          to_clear.delete(tar)
          remove_if_present(tar) if options[:force]
          unless File.exist?(tar) && File.size(tar) == ftp.size(remote_path + tar_path + tar)
            ftp.getbinaryfile(remote_path + tar_path + tar)
          end
        end
      end
      to_clear.each do |tar|
        remove_if_present(tar)
      end

      to_clear = rubys
      tars.each do |tar|
        ruby = File.basename(tar, '.tar.bz2')
        to_clear.delete(ruby)
        remove_if_present(ruby) if options[:force]
        unless File.directory?(ruby)
          system('tar', '-xjf', tar)
        end
      end
      to_clear.each do |ruby|
        remove_if_present(ruby)
      end
    end

    def self.add_rdoc_tasks
      rubys.each do |ruby|
        version = ruby.split('-', 2)[1]
        add_rdoc_task(
          :name_parts => [version],
          :src_path => ruby,
          :doc_path => ruby
        )
      end
    end
  end
end
