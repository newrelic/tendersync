require File.dirname(__FILE__) + '/spec_helper.rb'

describe Tendersync::Document do
  
  
  before do
    @doc_source = File.read("spec/fixtures/passenger_restart_issues")
  end
  
  it "should generate an index" do
    index = Tendersync::Document.new
    doc = Tendersync::Document.load("doc", StringIO.new(@doc_source))
    Tendersync::Document.stubs(:each).yields(doc)
    index.refresh_index
    index.body.should =~ /\* How to Fix it/
    index.body.should =~ /###/
  end
  
  it "should load from a file" do
    doc = Tendersync::Document.load("doc", StringIO.new(@doc_source))
    doc.title.should == "I updated the agent and restarted Passenger but it didn't pick up the new agent."
    doc.permalink.should == 'passenger_restart_issues'
    doc.keywords.should == 'passenger restart'
    doc.body.should =~ /^When you update/
  end
  it "should print with fields" do
    doc = Tendersync::Document.new :title => 'Title!', :body => "body!\nbody!"
    doc.to_s.should == <<-DOC.gsub(/^\s+/,'')
      ---------------------------- title ----------------------------
      Title!
      ---------------------------- body ----------------------------
      body!\nbody!
    DOC
  end
  
  it "should load from a form" do
    fields = { 'faq[title]' => 'title!', 'faq[body]' => "body by\nbill"}.collect do | key, value |
      f = Mechanize::Form::Field.new(key, value)
      f.name = key
      f
    end
    form = stub(:action => '/faqs/123/edit', :fields => fields)
    doc = Tendersync::Document.from_form("doc", form)
    doc.title.should == "title!"
    doc.document_id.should == '123'
    doc.body.should == "body by\nbill"
    doc.to_s.should == <<EOF.gsub(/^ */,'')
---------------------------- section ----------------------------
doc
---------------------------- document_id ----------------------------
123
---------------------------- title ----------------------------
title!
---------------------------- body ----------------------------
body by
bill
EOF
  end
end

