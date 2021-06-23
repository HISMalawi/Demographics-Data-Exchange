require 'rails_helper'

RSpec.describe Config, type: :model do
  subject {
    described_class.new(config:        "someconfig",
                        config_value:  "someconfig_value",
                        description:   "some description",
                        uuid:          "hbfhdd888fd9fdubfdybd",
                        created_at:    DateTime.now,
                        updated_at:    DateTime.now,)
  }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

end
