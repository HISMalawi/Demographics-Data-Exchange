require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do

  def authenticated_header(user)
    token = Knock::AuthToken.new(payload: { sub: user.id}).token
    {'Authorization': "Bearer #{token}"}
  end

  describe '/v1/verify_token/' do
    URL = '/v1/verify_token/'
    UATH_URL = '/v1/verify_token/'
  

    context 'when the request with no authentication header' do
      it 'should return unauth for retrieve current user info before login' do
        post URL
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the request contains an aunthentication header' do
      it 'should return the user info' do
        user = create(:user)

        get URL, headers: authenticated_header(user)
        puts response.body
      end
    end
  end


  describe "GET /show" do
    it "request for all users" do
      user = User.add_user(username: "TestUser",password_digest: "ghjgfdnnvn778")
      get api_v1_users_path
      expect(response).to be_successful
      expect(response.body).to include("TestUser")
    end
  end 
end

