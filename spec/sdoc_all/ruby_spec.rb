require File.dirname(__FILE__) + '/../spec_helper.rb'

class SdocAll
  describe Ruby do
    describe "subroutines" do
      describe "match_ruby_archive" do
        it "should return nil if does not match" do
          Ruby.match_ruby_archive('').should be_nil
          Ruby.match_ruby_archive('ruby').should be_nil
          Ruby.match_ruby_archive('ruby-1.2.3-p666.tar').should be_nil
        end

        %w(tar.bz2 tar.gz zip).each do |ext|
          it "should return info if match" do
            @archive = Ruby.match_ruby_archive("path/ruby-1.2.3-p666.#{ext}")
            @archive.should be_an(Ruby::ArchiveInfo)
            @archive.path.should == "path/ruby-1.2.3-p666.#{ext}"
            @archive.name.should == "ruby-1.2.3-p666.#{ext}"
            @archive.full_version.should == "1.2.3-p666"
            @archive.extension.should == ext
            @archive.version.should == [1, 2, 3, 666]
          end
        end
      end

      describe "last_matching_ruby_archive" do
        it "should return nil if could nothing match" do
          Ruby.last_matching_ruby_archive('2.0.0', %w(path/ruby-1.2.3-p666.zip .DS_Store)).should be_nil
        end

        it "should return latest matching" do
          @archive = Ruby.last_matching_ruby_archive('2.0.0', %w(
            path/ruby-1.0.0-p333.zip
            path/ruby-2.0.0-p444.zip
            path/ruby-3.0.0-p444.zip
            path/ruby-2.0.0-p666.zip
            path/ruby-3.0.0-p666.zip
            path/ruby-2.0.0-p555.zip
            path/ruby-3.0.0-p777.zip
            .DS_Store
          ))
          @archive.should be_an(Ruby::ArchiveInfo)
          @archive.path.should == "path/ruby-2.0.0-p666.zip"
        end
      end

      describe "find_matching_archive" do
        it "should call last_matching_ruby_archive for all files in sources" do
          @files = mock(:files)
          @children = mock(:children)
          @children.should_receive(:select).and_return(@files)
          @sources_path = mock(:sources_path, :parent => mock(:parent, :children => @children))
          Ruby.stub!(:sources_path).and_return(@sources_path)

          Ruby.should_receive(:last_matching_ruby_archive).with('1.2.3', @files)
          Ruby.find_matching_archive('1.2.3')
        end
      end

      describe "download_matching_archive" do
        before do
          @ftp = mock(:ftp, :debug_mode= => nil, :passive= => nil, :login => nil)
          @ftp.should_receive(:chdir).with('/pub/ruby')
          @list = ['mode user ... a', 'mode user ... b', 'mode user ... c']
          @paths = ['/pub/ruby/a', '/pub/ruby/b', '/pub/ruby/c']
          @ftp.should_receive(:list).with('ruby-*.tar.bz2').and_return(@list)
          Net::FTP.should_receive(:open).with('ftp.ruby-lang.org').and_yield(@ftp)
        end

        it "should not download anything if no matces" do
          @ftp.should_not_receive(:size)
          @ftp.should_not_receive(:getbinaryfile)

          Ruby.should_receive(:last_matching_ruby_archive).with('1.2.3', @paths).and_return(nil)
          Ruby.download_matching_archive('1.2.3')
        end

        describe "when match" do
          before do
            @tar = mock(:tar, :name => 'abc', :path => '/path')
          end

          it "should download if it does not exist locally" do
            File.stub!(:exist?).and_return(false)
            @ftp.should_receive(:getbinaryfile)

            Ruby.should_receive(:last_matching_ruby_archive).with('1.2.3', @paths).and_return(@tar)
            Ruby.download_matching_archive('1.2.3')
          end

          it "should download if local file size is not equal to remote" do
            File.stub!(:exist?).and_return(true)
            File.stub!(:size).and_return(1000)
            @ftp.stub!(:size).and_return(2000)
            @ftp.should_receive(:getbinaryfile)

            Ruby.should_receive(:last_matching_ruby_archive).with('1.2.3', @paths).and_return(@tar)
            Ruby.download_matching_archive('1.2.3')
          end

          it "should not download if local file size is to remote" do
            File.stub!(:exist?).and_return(true)
            File.stub!(:size).and_return(2000)
            @ftp.stub!(:size).and_return(2000)
            @ftp.should_not_receive(:getbinaryfile)

            Ruby.should_receive(:last_matching_ruby_archive).with('1.2.3', @paths).and_return(@tar)
            Ruby.download_matching_archive('1.2.3')
          end
        end
      end

      describe "find_or_download_matching_archive" do
        before do
          @archive = mock(:archive)
        end

        it "should immediately return match if update not allowed" do
          Ruby.should_receive(:find_matching_archive).with('1.2.3').once.and_return(@archive)
          Ruby.should_not_receive(:download_matching_archive)

          Ruby.find_or_download_matching_archive('1.2.3', :update => false).should == @archive
        end

        it "should downlaod and return match if update allowed" do
          Ruby.should_receive(:download_matching_archive).with('1.2.3').once.ordered
          Ruby.should_receive(:find_matching_archive).with('1.2.3').once.ordered.and_return(@archive)

          Ruby.find_or_download_matching_archive('1.2.3', :update => true).should == @archive
        end

        it "should downlaod and return match if not found local" do
          Ruby.should_receive(:find_matching_archive).with('1.2.3').once.ordered.and_return(nil, @archive)
          Ruby.should_receive(:download_matching_archive).with('1.2.3').once.ordered

          Ruby.find_or_download_matching_archive('1.2.3').should == @archive
        end

        it "should raise if can not find local or downlaod archive" do
          Ruby.should_receive(:find_matching_archive).with('1.2.3').once.ordered.and_return(nil, nil)
          Ruby.should_receive(:download_matching_archive).with('1.2.3').once.ordered

          proc{
            Ruby.find_or_download_matching_archive('1.2.3').should == @archive
          }.should raise_error(SdocAll::ConfigError)
        end
      end
    end

    it "should raise error if version not specified" do
      proc{ Ruby.new(nil).add_tasks }.should raise_error(SdocAll::ConfigError)
    end

    it "should raise error if version is blank" do
      proc{ Ruby.new(:version => ' ').add_tasks }.should raise_error(SdocAll::ConfigError)
    end

    describe "extracting archive and adding task" do
      before do
        @path = mock(:path)
        @sources_path = mock(:sources_path)
        @archive = mock(:archive, :full_version => '1.2.3-p666', :extension => 'tar.bz2', :path => 'sources/ruby-1.2.3-p666.tar.bz2')
        @sources_path.should_receive(:+).with('1.2.3-p666').and_return(@path)
        Ruby.stub!(:sources_path).and_return(@sources_path)
        Ruby.should_receive(:find_or_download_matching_archive).with('1.2.3')
        Ruby.should_receive(:find_or_download_matching_archive).with('1.2.3', :update => true).and_return(@archive)
        Base.stub!(:add_task)
      end

      it "should not extract archive if matching directory already exists" do
        @path.stub!(:directory?).and_return(true)
        Base.should_not_receive(:remove_if_present)
        Base.should_not_receive(:system)

        Ruby.new(:version => '1.2.3').add_tasks(:update => true)
      end

      it "should extract archive if matching directory does not exist" do
        @path.stub!(:directory?).and_return(false)
        Base.should_receive(:remove_if_present).with(@sources_path)
        Base.should_receive(:system).with("tar", "-xjf", "sources/ruby-1.2.3-p666.tar.bz2", "-C", @sources_path)
        @path2 = mock(:path2)
        @sources_path.should_receive(:+).with('ruby-1.2.3-p666').and_return(@path2)
        File.should_receive(:rename).with(@path2, @path)

        Ruby.new(:version => '1.2.3').add_tasks(:update => true)
      end

      it "should finally add task" do
        @path.stub!(:directory?).and_return(true)
        Base.should_not_receive(:remove_if_present)
        Base.should_not_receive(:system)
        Base.should_receive(:add_task).with(:doc_path => "ruby-1.2.3-p666", :src_path => @path)

        Ruby.new(:version => '1.2.3').add_tasks(:update => true)
      end
    end
  end
end
