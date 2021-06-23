require 'rails_helper'

RSpec.describe PersonDetail, type: :model do
  
  subject{
    described_class.new(
      first_name: "Mary",
      last_name: "Doe",
      last_edited: DateTime.now,
      date_registered: DateTime.now,
      person_uuid: "sdfdbfgfghghgf",
      location_created_at: 40,
      creator: "somename",
      )
  }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

end
