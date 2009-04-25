require File.dirname(__FILE__) + '/spec_helper.rb'

describe SdocAll do
  config_yaml = %Q{
    sdoc:
    - ruby:
        path: 1.8.6
    - rails
    - rails:
    - gems:
        exclude:
        - rails
        - mysql
    - plugins:
        path: ~/.plugins
    - path: ~/lib/bin
  }

  describe "run" do
    it "should call read_config, call run for each task and merge docs" do
      SdocAll::Base.stub!(:docs_path).and_return(Pathname.new('/docs'))
      SdocAll::Base.stub!(:public_path).and_return(Pathname.new('/public'))

      @tasks = []
      @each = @tasks.should_receive(:each_with_progress)
      %w(a b c).each do |c|
        task = mock(c, :doc_path => "#{c}", :src_path => "/sources/#{c}", :title => "<#{c}>")
        task.should_receive(:run)
        File.should_receive(:file?).with(Pathname.new("/docs/#{c}/index.html")).and_return(true)
        @each.and_yield(task)
        @tasks << task
      end

      SdocAll.should_receive(:read_config)
      SdocAll::Base.should_receive(:tasks).and_return(@tasks)
      SdocAll::Base.should_receive(:system).with('sdoc-merge', '-o', Pathname.new('/public'), '-t', 'all', '-n', '<a>,<b>,<c>', '-u', '/docs/a /docs/b /docs/c', 'a', 'b', 'c')
      SdocAll.should_receive(:store_current_sdoc_version)
      SdocAll.run
    end
  end

  describe "read_config" do
    it "should read config" do
      YAML.should_receive(:load_file).with('config.yml').and_return(YAML.load(config_yaml))

      SdocAll::Base.should_receive(:to_document).ordered.with('ruby', {'path' => '1.8.6'})
      SdocAll::Base.should_receive(:to_document).ordered.with('rails', {})
      SdocAll::Base.should_receive(:to_document).ordered.with('rails', nil)
      SdocAll::Base.should_receive(:to_document).ordered.with('gems', {'exclude' => ['rails', 'mysql']})
      SdocAll::Base.should_receive(:to_document).ordered.with('plugins', {'path' => '~/.plugins'})
      SdocAll::Base.should_receive(:to_document).ordered.with('path', '~/lib/bin')

      SdocAll.read_config
    end

    it "should raise if config is empty" do
      YAML.stub!(:load_file).and_return(nil)
      proc{ SdocAll.read_config }.should raise_error(SdocAll::ConfigError)
    end

    it "should raise if config is not a hash" do
      YAML.stub!(:load_file).and_return('')
      proc{ SdocAll.read_config }.should raise_error(SdocAll::ConfigError)
    end

    it "should raise if sdoc is empty" do
      YAML.stub!(:load_file).and_return('')
      proc{ SdocAll.read_config }.should raise_error(SdocAll::ConfigError)
    end

    it "should raise if sdoc entry is wrong" do
      YAML.stub!(:load_file).and_return YAML.load(%Q{
        sdoc:
        - ruby:
          version: 1.8.6
      })
      proc{ SdocAll.read_config }.should raise_error(SdocAll::ConfigError)
    end
  end
end
