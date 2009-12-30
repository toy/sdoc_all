require 'rubygems'
gem 'rspec'
require 'spec'
require 'stringio'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sdoc_all'

Spec::Runner.configure do |config|
  config.prepend_before do
    SdocAll::Base.stub!(:system)
    SdocAll::Base.stub!(:remove_if_present)
    class <<Dir
      alias original_chdir chdir
    end
    Dir.stub!(:chdir).and_yield
    Net::FTP.stub!(:open)
    File.stub!(:symlink)
    @progress_io = StringIO.new
    Progress.stub!(:io).and_return(@progress_io)

    SdocAll.constants.each do |constant|
      klass = SdocAll.const_get(constant)
      if klass.is_a?(Class) && klass.superclass == SdocAll::Base
        klass.stub!(:sources_path).and_return(Pathname.new("sources/#{constant.downcase}"))
      end
    end
  end
end
