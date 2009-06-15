require File.dirname(__FILE__) + '/spec_helper.rb'

describe Tendersync::Runner do

  before do
    Tendersync::Runner.any_instance.stubs(:save_config_file)
  end
  
  it "should process no args" do
    Tendersync::Runner.new []
  end
  
end
