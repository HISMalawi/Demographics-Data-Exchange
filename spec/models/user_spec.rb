require 'rails_helper'


RSpec.describe User, type: :model do
subject{
    described_class.new(username: "test",
                        password_digest:     "fdjsbjbhiihhjk.dfddfdf",
                       )
  }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end
  
  it "is not valid without username" do
    subject.username = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without password digest" do
    subject.password_digest = nil
    expect(subject).to_not be_valid
  end
  
end
