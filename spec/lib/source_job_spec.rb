require 'spec_helper'

describe SourceJob do

  let(:retrieval_status) { FactoryGirl.create(:retrieval_status) }
  let(:citeulike) { FactoryGirl.create(:citeulike) }
  let(:rs_id) { "#{retrieval_status.source.name}:#{retrieval_status.article.doi_escaped}" }

  subject { SourceJob.new([retrieval_status.id], citeulike.id) }

  before(:each) do
    subject.put_alm_database
  end

  after(:each) do
    subject.delete_alm_database
  end

  it "should perform and get data" do
    stub = stub_request(:get, citeulike.get_query_url(retrieval_status.article)).to_return(:body => File.read(fixture_path + 'citeulike.xml'), :status => 200)
    result = subject.perform_get_data(retrieval_status)
    result[:event_count].should eq(25)
    rh_id = result[:retrieval_history_id]

    rs_result = subject.get_alm_data(rs_id)
    rs_result.should include("source" => retrieval_status.source.name,
                             "doi" => retrieval_status.article.doi,
                             "doc_type" => "current",
                             "_id" =>  "#{retrieval_status.source.name}:#{retrieval_status.article.doi}")
    rh_result = subject.get_alm_data(rh_id)
    rh_result.should include("source" => retrieval_status.source.name,
                             "doi" => retrieval_status.article.doi,
                             "doc_type" => "history",
                             "_id" => "#{rh_id}")
  end

  it "should perform and update CouchDB" do
    stub = stub_request(:get, citeulike.get_query_url(retrieval_status.article)).to_return(:body => File.read(fixture_path + 'citeulike.xml'), :status => 200)
    result = subject.perform_get_data(retrieval_status)
    rh_id = result[:retrieval_history_id]

    rs_result = subject.get_alm_data(rs_id)
    rs_result.should include("source" => retrieval_status.source.name,
                             "doi" => retrieval_status.article.doi,
                             "doc_type" => "current",
                             "_id" => "#{retrieval_status.source.name}:#{retrieval_status.article.doi}")
    rh_result = subject.get_alm_data(rh_id)
    rh_result.should include("source" => retrieval_status.source.name,
                             "doi" => retrieval_status.article.doi,
                             "doc_type" => "history",
                             "_id" => "#{rh_id}")

    new_result = subject.perform_get_data(retrieval_status)
    new_rh_id = new_result[:retrieval_history_id]
    new_rh_id.should_not eq(rh_id)

    new_rs_result = subject.get_alm_data(rs_id)
    new_rs_result.should include("source" => retrieval_status.source.name,
                                 "doi" => retrieval_status.article.doi,
                                 "doc_type" => "current",
                                 "_id" => "#{retrieval_status.source.name}:#{retrieval_status.article.doi}")
    new_rs_result["_rev"].should_not be_nil
    new_rs_result["_rev"].should_not eq(rs_result["_rev"])

    new_rh_result = subject.get_alm_data(new_rh_id)
    new_rh_result.should include("source" => retrieval_status.source.name,
                                 "doi" => retrieval_status.article.doi,
                                 "doc_type" => "history",
                                 "_id" => "#{new_rh_id}")
    new_rh_result["_rev"].should_not be_nil
    new_rh_result["_id"].should_not eq(rh_result["_id"])
  end

  it "should perform and get no data" do
    stub = stub_request(:get, citeulike.get_query_url(retrieval_status.article)).to_return(:body => File.read(fixture_path + 'citeulike_nil.xml'), :status => 200)
    result = subject.perform_get_data(retrieval_status)
    result[:event_count].should eq(0)
  end

  it "should perform and get skipped" do
    retrieval_status = FactoryGirl.create(:retrieval_status, :missing_mendeley)
    scheduled_at = retrieval_status.scheduled_at
    stub = stub_request(:get, retrieval_status.source.get_query_url(retrieval_status.article, "doi")).to_return(:body => File.read(fixture_path + 'mendeley_nil.json'), :status => 200)
    stub_pubmed = stub_request(:get, retrieval_status.source.get_query_url(retrieval_status.article, "pmid")).to_return(:body => File.read(fixture_path + 'mendeley_nil.json'), :status => 200)
    stub_title = stub_request(:get, retrieval_status.source.get_query_url(retrieval_status.article, "title")).to_return(:body => File.read(fixture_path + 'mendeley_nil.json'), :status => 200)
    result = subject.perform_get_data(retrieval_status)
    result[:event_count].should eq(0)
    result[:retrieval_history_id].should be_nil
  end

  it "should perform and get error" do
    scheduled_at = retrieval_status.scheduled_at
    stub = stub_request(:get, citeulike.get_query_url(retrieval_status.article)).to_return(:status => [408])
    result = subject.perform_get_data(retrieval_status)
    result[:event_count].should be_nil
    result[:retrieval_history_id].should be_nil

    Alert.count.should == 1
    alert = Alert.first
    alert.class_name.should eq("Net::HTTPRequestTimeOut")
    alert.status.should == 408
    alert.source_id.should == citeulike.id
  end
end
