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
      m.template_copy_each %w(sdoc.config.yml.erb), nil, :assigns => {:sdoc_options => {
        'ruby' => options[:ruby],
        'rails' => options[:rails],
        'exclude' => options[:exclude],
        'plugins_path' => options[:plugins_path],
      }}
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

      opts.on("-r", "--ruby=\"version\"", String, "version of ruby you want to be documented like 1.8 or 1.8.6", "Default: latest") { |o| options[:ruby] = o }
      opts.on("-a", "--rails=\"version\"", String, "version of rails you want to be documented like 2. or 2.3.2", "Default: latest") { |o| options[:rails] = o }
      opts.on("-e", "--exclude=\"pathes\"", Array, "what to exclude separated with comma like gems/actionmailer or gems/actionpack,gems/rails", "Default: gems related to rails") { |o| options[:exclude] = o }
      opts.on("-p", "--plugins_path=\"path\"", Array, "directory in which you store plugins you use are stored", "Default: ~/.plugins") { |o| options[:plugins_path] = o }

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
