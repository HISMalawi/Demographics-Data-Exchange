require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'Ip address should be unique' do
    it 'Ip address shoud be unique' do
      Location.create(name: 'test', ip_address: '127.0.0.1', creator: 1)
      location = Location.new(ip_address: '127.0.0.1')
      expect(location).to_not be_valid
    end
  end
end
