class Location < ApplicationRecord
  
  default_scope { where(voided: 0) }
 
  def self.get_location_by_name(name)
    location = Location.find_by_name(name)
    return location
  end
  
end
