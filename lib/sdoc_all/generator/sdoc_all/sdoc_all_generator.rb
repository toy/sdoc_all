class SdocAllGenerator < RubiGen::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    extract_options
  end

  def manifest
    record do |m|
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      m.file_copy_each %w(Rakefile)
      m.file_copy_each %w(sdoc.config.yml)
    end
  end

  protected
    def banner
      <<-EOS
Creates an app for all ruby related documentation
edit sdoc.config.yml.erb if you need
run rake tasks
wait until finished (it takes some time)
all your documentation is in public folder

note:
content of docs and sources folders can be destroyed during rebuild
public folder is destroyed and recreated every build!

USAGE: #{File.basename($0)} name
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'

      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end

    def extract_options
    end

    BASEDIRS = %w(
      docs
      public
      sources
    )
end
