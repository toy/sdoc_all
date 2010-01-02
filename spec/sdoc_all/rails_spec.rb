require File.dirname(__FILE__) + '/../spec_helper.rb'

describe SdocAll::Rails do
  before do
    SdocAll::Rails.stub!(:versions).and_return(['1.2.3', '1.3.5', '1.5.9'])
  end

  describe "adding task" do
    before do
      File.should_receive(:open).with('vendor/rails/railties/lib/tasks/documentation.rake')
    end

    it "should add task" do
      SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.3.5'))
      SdocAll::Rails.new(:version => '1.3.5').add_tasks
    end

    it "should use latest version if none given" do
      SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.5.9'))
      SdocAll::Rails.new(nil).add_tasks
    end

    it "should use lone argument as version" do
      SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.3.5'))
      SdocAll::Rails.new('1.3.5').add_tasks
    end
  end

  it "should raise for wrong version" do
    proc{
      SdocAll::Rails.new('1.1.1').add_tasks
    }.should raise_error(SdocAll::ConfigError)
  end

  describe "creating app" do
    before do
      SdocAll::Base.stub!(:add_task)
      File.stub!(:open)
    end

    it "should create rails app" do
      FileTest.should_receive(:directory?).with("sources/rails/1.3.5").and_return(false)
      SdocAll::Base.should_receive(:remove_if_present).with(Pathname.new("sources/rails/1.3.5"))
      SdocAll::Base.should_receive(:system).with("rails", Pathname.new("sources/rails/1.3.5"), "--freeze")
      SdocAll::Rails.new('1.3.5').add_tasks
    end

    it "should not create rails app if it already exists" do
      FileTest.should_receive(:directory?).with("sources/rails/1.3.5").and_return(true)
      SdocAll::Base.should_not_receive(:remove_if_present)
      SdocAll::Base.should_not_receive(:system)
      SdocAll::Rails.new('1.3.5').add_tasks
    end
  end
end
