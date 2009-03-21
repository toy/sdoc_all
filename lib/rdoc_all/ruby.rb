class RdocAll::Ruby < RdocAll::Base
  class << self
    def tars
      Dir['ruby-*.tar.bz2']
    end

    def rubys
      Dir['ruby-*'].select{ |path| File.directory?(path) }
    end

    def update_sources(options = {})
      to_clear = tars
      Net::FTP.open('ftp.ruby-lang.org') do |ftp|
        ftp.debug_mode = true
        ftp.passive = true
        ftp.login
        ftp.chdir('/pub/ruby')
        ftp.list('ruby-*.tar.bz2').each do |line|
          tar_path, tar = File.split(line.split.last)
          to_clear.delete(tar)
          remove_if_present(tar) if options[:force]
          unless File.exist?(tar)
            ftp.chdir('/pub/ruby' / tar_path)
            ftp.getbinaryfile(tar)
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

    def add_rdoc_tasks
      rubys.each do |ruby|
        add_rdoc_task(ruby)
      end
    end
  end
end
