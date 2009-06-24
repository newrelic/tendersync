require File.dirname(__FILE__) + '/spec_helper.rb'

describe Tendersync::Runner do
  
  before do
    Tendersync::Runner.any_instance.stubs(:save_config_file)
  end
  
  it "should process no args" do
    begin
      Tendersync::Runner.new []
    rescue Tendersync::Runner::Error => e
      e.message.should match(/Please enter a/)
    end
  end
  
  it "should process no args" do
    begin
      Tendersync::Runner.new []
    rescue Tendersync::Runner::Error => e
      e.message.should match(/Please enter a/)
    end
  end
  
  
end
