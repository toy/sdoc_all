require File.dirname(__FILE__) + '/../spec_helper.rb'

describe SdocAll::Gems do
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

    SdocAll::Gems.stub!(:latest_specs).and_return(@latest_specs)
    SdocAll::Gems.stub!(:all_specs).and_return(@all_specs)
  end

  it "should add one selected tasks" do
    SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.one-2'))
    SdocAll::Gems.new('one').add_tasks
  end

  it "should add two selected tasks" do
    SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.one-2'))
    SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.two-3'))
    SdocAll::Gems.new(['one', 'two']).add_tasks
  end

  it "should add tasks except excluded" do
    SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.four-1'))
    SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => 'gems.five-1'))
    SdocAll::Gems.new(:exclude => ['one', 'two', 'three']).add_tasks
  end

  it "should add tasks for latest gems" do
    @latest_specs.each do |gem_spec|
      SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => "gems.#{gem_spec.full_name}"))
    end
    SdocAll::Gems.new({}).add_tasks
  end

  it "should add tasks for all gems" do
    @all_specs.each do |gem_spec|
      SdocAll::Base.should_receive(:add_task).with(hash_including(:doc_path => "gems.#{gem_spec.full_name}"))
    end
    SdocAll::Gems.new(:versions => 'all').add_tasks
  end
end
