require "rails_helper"

RSpec.describe Api::V1::PeopleDetailsController, type: :routing do
  describe "routing" do
    

    it "routes to #create" do
      expect(post: "v1/add_person").to route_to("api/v1/people_details#create")
    end

    it "routes to #search_by_name_and_gender" do
      expect(post: "v1/search_by_name_and_gender").to route_to("api/v1/people_details#search_by_name_and_gender")
    end

    it "routes to #search_by_npid" do
      expect(post: "v1/search_by_npid").to route_to("api/v1/people_details#search_by_npid")
    end
  end
end
