require 'spec_helper'

describe Nature do
  
  before(:each) do
    @nature = FactoryGirl.create(:nature)
  end
  
  it "should report that there are no events if the doi is missing" do
    article_without_doi = FactoryGirl.build(:article, :doi => "")
    @nature.get_data(article_without_doi).should eq({ :events => [], :event_count => 0 })
  end
  
  context "use the Nature Blogs API" do
    it "should report if there are no events and event_count returned by the Nature Blogs API" do
      article_without_events = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0044294")
      stub = stub_request(:get, @nature.get_query_url(article_without_events)).to_return(:body => File.read(fixture_path + 'nature_nil.json'), :status => 200)
      @nature.get_data(article_without_events).should eq({ :events => [], :event_count => 0 })
      stub.should have_been_requested
    end
    
    it "should report if there are events and event_count returned by the Nature Blogs API" do
      @article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0008776")
      stub = stub_request(:get, @nature.get_query_url(@article)).to_return(:body => File.read(fixture_path + 'nature.json'), :status => 200)
      response = @nature.get_data(@article)
      response[:event_count].should eq(10)
      stub.should have_been_requested
    end
    
    it "should catch errors with the Nature Blogs API" do
      @article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0000001")
      stub = stub_request(:get, @nature.get_query_url(@article)).to_return(:status => 408)
      lambda { @nature.get_data(@article) }.should raise_error(Net::HTTPServerException)
      stub.should have_been_requested
    end
  end
end