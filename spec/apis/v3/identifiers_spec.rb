require "spec_helper"

describe "/api/v3/articles" do
  let(:user) { FactoryGirl.create(:user) }
  let(:api_key) { user.authentication_token }
  let(:error) { { "error" => "Article not found."} }

  context "missing api_key" do
    let(:article) { FactoryGirl.create(:article_with_events) }
    let(:uri) { "/api/v3/articles/info:doi/#{article.doi}"}
    let(:missing_key) { { "error" => "Missing or wrong API key."} }


    it "JSON" do
      get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
      last_response.status.should eql(401)
      last_response.body.should eq(missing_key.to_json)
      Alert.count.should == 1
      alert = Alert.first
      alert.class_name.should eq("Net::HTTPUnauthorized")
      alert.message.should include("Missing or wrong API key.")
      alert.content_type.should eq("application/json")
      alert.status.should == 401
    end

    it "XML" do
      get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
      last_response.status.should eql(401)
      last_response.body.should eq(missing_key.to_xml)
      Alert.count.should == 1
      alert = Alert.first
      alert.class_name.should eq("Net::HTTPUnauthorized")
      alert.message.should include("Missing or wrong API key.")
      alert.content_type.should eq("application/xml")
      alert.status.should == 401
    end
  end

  context "index" do
    let(:articles) { FactoryGirl.create_list(:article_with_events, 50) }

    context "articles found via DOI" do
      before(:each) do
        article_list = articles.collect { |article| "#{article.doi_escaped}" }.join(",")
        @uri = "/api/v3/articles?ids=#{article_list}&type=doi&api_key=#{api_key}"
      end

      it "no format" do
        get @uri
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)
        response.length.should eql(50)
        response.any? do |article|
          article["doi"] == articles[0].doi
          article["publication_date"] == articles[0].published_on.to_time.utc.iso8601
        end.should be_true
      end

      it "JSON" do
        get @uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)
        response.length.should eql(50)
        response.any? do |article|
          article["doi"] == articles[0].doi
          article["publication_date"] == articles[0].published_on.to_time.utc.iso8601
        end.should be_true
      end

      it "XML" do
        get @uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response.length.should eql(50)
        response.any? do |article|
          article["doi"] == articles[0].doi
          article["publication_date"] == articles[0].published_on.to_time.utc.iso8601
        end.should be_true
      end
    end

    context "articles found via PMID" do
      before(:each) do
        article_list = articles.collect { |article| "#{article.pub_med}" }.join(",")
        @uri = "/api/v3/articles?ids=#{article_list}&type=pmid&api_key=#{api_key}"
      end


      it "JSON" do
        get @uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)
        response.length.should eql(50)
        response.any? do |article|
          article["pmid"] == articles[0].pub_med
        end.should be_true
      end

      it "XML" do
        get @uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response.length.should eql(50)
        response.any? do |article|
          article["pub_med"] == articles[0].pub_med
          article["publication_date"] == articles[0].published_on.to_time.utc.iso8601
        end.should be_true
      end
    end

    context "no records found" do
      let(:uri) { "/api/v3/articles?api_key=#{api_key}"}

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_json)
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_xml)
      end
    end

  end

  context "show" do

    context "DOI" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:doi/#{article.doi}?api_key=#{api_key}"}

      it "no format" do
        get uri
        last_response.status.should eql(200)

        response_article = JSON.parse(last_response.body)[0]
        response_source = response_article["sources"][0]
        response_article["doi"].should eql(article.doi)
        response_article["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response_source["metrics"]["total"].should eq(article.retrieval_statuses.first.retrieval_histories.first.event_count)
        response_source["events"].should be_nil
        response_source["histories"].should be_nil
      end

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)[0]
        response_source = response["sources"][0]
        response["doi"].should eql(article.doi)
        response["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response_source["metrics"]["total"].should eq(article.retrieval_statuses.first.retrieval_histories.first.event_count)
        response_source["events"].should be_nil
        response_source["histories"].should be_nil
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response_source = response["sources"]["source"]
        response["doi"].should_not be_nil
        response["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response_source["metrics"]["total"].to_i.should eq(article.retrieval_statuses.first.retrieval_histories.first.event_count)
        response_source["events"].should be_nil
        response_source["histories"].should be_nil
      end

    end

    context "PMID" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:pmid/#{article.pub_med}?api_key=#{api_key}"}

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)[0]
        response["pmid"].should eql(article.pub_med.to_s)
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response["doi"].should_not be_nil
        response["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response["pmid"].should eql(article.pub_med.to_s)
      end

    end

    context "PMCID" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:pmcid/PMC#{article.pub_med_central}?api_key=#{api_key}"}

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)[0]
        response["pmcid"].should eql(article.pub_med_central.to_s)
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response["doi"].should_not be_nil
        response["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response["pmcid"].should eql(article.pub_med_central.to_s)
      end

    end

    context "Mendeley" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:mendeley/#{article.mendeley}?api_key=#{api_key}"}

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response_article = JSON.parse(last_response.body)[0]
        response_article["mendeley"].should eql(article.mendeley)
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(200)

        response = Nori.new(:advanced_typecasting => false).parse(last_response.body)
        response = response["articles"]["article"]
        response["doi"].should_not be_nil
        response["publication_date"].should eql(article.published_on.to_time.utc.iso8601)
        response["mendeley"].should eql(article.mendeley)
      end

    end

    context "wrong DOI" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:doi/#{article.doi}xx?api_key=#{api_key}"}


      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_json)
      end

      it "XML" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_xml)
      end
    end

    context "article not found when using format as file extension" do
      let(:article) { FactoryGirl.create(:article_with_events) }
      let(:uri) { "/api/v3/articles/info:doi/#{article.doi}xx"}

      it "JSON" do
        get "#{uri}.json?api_key=#{api_key}", nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_json)
      end

      it "XML" do
        get "#{uri}.xml?api_key=#{api_key}", nil, { 'HTTP_ACCEPT' => "application/xml" }
        last_response.status.should eql(404)
        last_response.body.should eq(error.to_xml)
      end
    end

  end
end
