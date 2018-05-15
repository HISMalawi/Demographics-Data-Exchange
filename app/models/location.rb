class Location < ApplicationRecord
  
  def self.get_location_by_name(name)
    location = Location.find_by_name(name)
    return location
  end
  
end
