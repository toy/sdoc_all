require File.dirname(__FILE__) + '/../spec_helper.rb'

class SdocAll
  describe Plugins do
    def plugin_mock(name, options = {})
      mock(:plugin, :basename => name, :directory? => !options[:not_directory], :+ => mock(:git_dir, :directory? => !options[:no_git]))
    end

    before do
      @one = mock(:one, :expand_path => mock(:one_expanded, :directory? => true))
    end

    describe "path" do
      before do
        @one.stub!(:mkpath)
        @one.expand_path.stub!(:children).and_return([])
      end

      it "should set default path if none given" do
        Plugins.stub!(:sources_path).and_return('sources/plugins')
        Pathname.should_receive(:new).with('sources/plugins').and_return(@one)
        Plugins.new(nil).add_tasks
      end

      it "should asume that lone argument is path" do
        Pathname.should_receive(:new).with('one').and_return(@one)
        Plugins.new('one').add_tasks
      end
    end

    describe "update" do
      before do
        @a = plugin_mock('a')
        @b = plugin_mock('b', :no_git => true)
        @c = plugin_mock('c', :not_directory => true)
        @one.expand_path.should_receive(:children).and_return([@a, @b, @c])
        Pathname.should_receive(:new).with('one').and_return(@one)
      end

      it "should update plugins using git" do
        Base.should_receive(:system).once.with("git fetch origin && git reset --hard origin")
        Base.stub!(:add_task)
        Plugins.new(:path => 'one').add_tasks(:update => true)
      end

      it "should not update plugins when config disables it" do
        Base.should_not_receive(:system)
        Base.stub!(:add_task)
        Plugins.new(:path => 'one', :update => false).add_tasks
      end
    end

    describe "adding" do
      before do
        @a = plugin_mock('a')
        @b = plugin_mock('b')
        @c = plugin_mock('c')
        @one.expand_path.should_receive(:children).and_return([@a, @b, @c])
        Pathname.should_receive(:new).with('one').and_return(@one)
      end

      it "should add tasks" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.a'))
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.b'))
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.c'))
        Plugins.new(:path => 'one').add_tasks
      end

      it "should add only selected tasks" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.a'))
        Plugins.new(:path => 'one', :only => 'a').add_tasks
      end

      it "should add not excluded tasks" do
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.a'))
        Base.should_receive(:add_task).with(hash_including(:doc_path => 'plugins.c'))
        Plugins.new(:path => 'one', :exclude => 'b').add_tasks
      end
    end
  end
end
