require File.dirname(__FILE__) + '/../spec_helper.rb'

class SdocAll
  describe FileList do
    before do
      @list = FileList.new
    end

    it "should include well" do
      @list.include('R*')
      @list.should == %w(Rakefile README.rdoc)
    end

    it "should exclude well" do
      @list.include('R*')
      @list.exclude('Rake*')
      @list.should == %w(README.rdoc)
    end

    it "should exclude non existing files from list" do
      @list.include('R*')
      @list.include('non existing')
      @list.should == %w(Rakefile README.rdoc)
    end

    it "should exclude duplicates" do
      @list.include('R*')
      @list.include('R*')
      @list.should == %w(Rakefile README.rdoc)
    end

    it "should not fail if directory changes after resolve" do
      @list.include('R*')
      @list.resolve
      Dir.original_chdir('lib') do
        @list.should == %w(Rakefile README.rdoc)
      end
    end
  end
end
