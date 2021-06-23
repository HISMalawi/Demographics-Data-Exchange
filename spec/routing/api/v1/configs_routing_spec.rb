require "rails_helper"

RSpec.describe Api::V1::ConfigsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/v1/show_index").to route_to("api/v1/configs#index")
    end

    it "routes to #show" do
      expect(get: "/v1/show_config").to route_to("api/v1/configs#show")
    end


    it "routes to #create" do
      expect(post: "/v1/create_config").to route_to("api/v1/configs#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/v1/update_via_put_config").to route_to("api/v1/configs#update")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/v1/update_config").to route_to("api/v1/configs#update")
    end

    it "routes to #destroy" do
      expect(delete: "/v1/delete_config").to route_to("api/v1/configs#destroy")
    end
  end
end
