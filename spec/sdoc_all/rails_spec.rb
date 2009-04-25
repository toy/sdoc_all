require File.dirname(__FILE__) + '/../spec_helper.rb'

class SdocAll
  describe Rails do
    before do
      Rails.stub!(:versions).and_return(['1.2.3', '1.3.5', '1.5.9'])
    end

    describe "adding task" do
      before do
        File.should_receive(:open).with('vendor/rails/railties/lib/tasks/documentation.rake')
      end

      it "should add task" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.3.5'))
        Rails.new(:version => '1.3.5').add_tasks
      end

      it "should use latest version if none given" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.5.9'))
        Rails.new(nil).add_tasks
      end

      it "should use lone argument as version" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'rails-1.3.5'))
        Rails.new('1.3.5').add_tasks
      end
    end

    it "should raise for wrong version" do
      proc{
        Rails.new('1.1.1').add_tasks
      }.should raise_error(SdocAll::ConfigError)
    end

    describe "creating app" do
      before do
        Base.stub!(:add_task)
        File.stub!(:open)
      end

      it "should create rails app" do
        FileTest.should_receive(:directory?).with("sources/rails/1.3.5").and_return(false)
        Base.should_receive(:remove_if_present).with(Pathname.new("sources/rails"))
        Base.should_receive(:system).with("rails", Pathname.new("sources/rails/1.3.5"), "--freeze")
        Rails.new('1.3.5').add_tasks
      end

      it "should not create rails app if it already exists" do
        FileTest.should_receive(:directory?).with("sources/rails/1.3.5").and_return(true)
        Base.should_not_receive(:remove_if_present)
        Base.should_not_receive(:system)
        Rails.new('1.3.5').add_tasks
      end
    end
  end
end
