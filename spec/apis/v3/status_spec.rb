require "spec_helper"

describe "/api/v3/status" do

  context "index" do
    let(:user) { FactoryGirl.create(:admin_user) }
    let(:uri) { "/api/v3/status?api_key=#{user.authentication_token}" }

    context "get response" do
      before(:each) do
        @articles = FactoryGirl.create_list(:article, 5)
        @api_responses = FactoryGirl.create_list(:api_response, 10)
      end

      it "JSON" do
        get uri, nil, { 'HTTP_ACCEPT' => "application/json" }
        last_response.status.should eql(200)

        response = JSON.parse(last_response.body)
        response["articles_count"].should == 5
        response["responses_count"].should == 10
        response["users_count"].should == 1
        response["version"].should == VERSION
      end
    end
  end
end