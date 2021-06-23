require 'rails_helper'

RSpec.describe "Api::V1::Syncs", type: :request do
  describe "GET /api/v1/syncs" do
    it "works! (now write some real specs)" do
      get api_v1_syncs_path
      expect(response).to have_http_status(200)
    end
  end
end
