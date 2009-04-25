require File.dirname(__FILE__) + '/../spec_helper.rb'

class SdocAll
  describe Gems do
    def gem_mock(name, version)
      mock(:gem, {
        :name => name,
        :version => version,
        :full_name => "#{name}-#{version.join('.')}",
        :sort_obj => [name, version],
        :rdoc_options => [],
        :full_gem_path => name,
        :require_paths => [],
        :extra_rdoc_files => []
      })
    end

    before do
      one_1 = gem_mock('one', [1])
      one_2 = gem_mock('one', [2])
      two_1 = gem_mock('two', [1])
      two_2 = gem_mock('two', [2])
      two_3 = gem_mock('two', [3])
      three = gem_mock('three', [1])
      four = gem_mock('four', [1])
      five = gem_mock('five', [1])

      @all_specs = [one_1, one_2, two_1, two_2, two_3, three, four, five]
      @latest_specs = [one_2, two_3, three, four, five]

      Gems.stub!(:latest_specs).and_return(@latest_specs)
      Gems.stub!(:all_specs).and_return(@all_specs)
    end

    it "should add one selected tasks" do
      Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.one-2'))
      Gems.new('one').add_tasks
    end

    it "should add two selected tasks" do
      Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.one-2'))
      Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.two-3'))
      Gems.new(['one', 'two']).add_tasks
    end

    it "should add tasks except excluded" do
      Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.four-1'))
      Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.five-1'))
      Gems.new(:exclude => ['one', 'two', 'three']).add_tasks
    end

    it "should add tasks for latest gems" do
      @latest_specs.each do |gem_spec|
        Base.should_receive(:add_task).with(hash_including(:doc_path => "gems.#{gem_spec.full_name}"))
      end
      Gems.new({}).add_tasks
    end

    it "should add tasks for all gems" do
      @all_specs.each do |gem_spec|
        Base.should_receive(:add_task).with(hash_including(:doc_path => "gems.#{gem_spec.full_name}"))
      end
      Gems.new(:versions => 'all').add_tasks
    end
  end
end
