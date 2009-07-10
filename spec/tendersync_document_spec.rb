require File.dirname(__FILE__) + '/spec_helper.rb'

describe Tendersync::Document do
  
  
  before do
    @doc_source = File.read("spec/fixtures/passenger_restart_issues")
  end
  
  it "should load from a file" do
    doc = Tendersync::Document.load("doc", StringIO.new(@doc_source))
    doc.title.should == "I updated the agent and restarted Passenger but it didn't pick up the new agent."
    doc.permalink.should == 'passenger_restart_issues'
    doc.keywords.should == 'passenger restart'
    doc.body.should =~ /^When you update/
  end
  
  it "should load from a form" do
    fields = { 'title' => 'title!', 'id' => '123', 'body' => 'body by\n\r bill'}.collect do | key, value |
      WWW::Mechanize::Form::Field.new(key, value)
    end
    form = stub(:action => '/faqs/123/edit', :fields => fields) 
    doc = Tendersync::Document.from_form("doc", form)
    doc.keys.map{|k|k.to_s}.sort.should == %w[body document_id section title]
    doc.title.should == "title!"
    doc.id.should == '123'
    doc.body.should == "body by bill"
  end
  
end
