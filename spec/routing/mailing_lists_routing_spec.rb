require "rails_helper"

RSpec.describe MailingListsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/mailing_lists").to route_to("mailing_lists#index")
    end

    it "routes to #show" do
      expect(get: "/mailing_lists/1").to route_to("mailing_lists#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/mailing_lists").to route_to("mailing_lists#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/mailing_lists/1").to route_to("mailing_lists#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/mailing_lists/1").to route_to("mailing_lists#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/mailing_lists/1").to route_to("mailing_lists#destroy", id: "1")
    end
  end
end
