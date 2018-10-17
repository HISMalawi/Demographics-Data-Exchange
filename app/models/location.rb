class Location < ApplicationRecord
  
  default_scope { where(voided: 0) }
 
  def self.get_location_by_name(name)
    location = Location.find_by_name(name)
    return location
  end

  def total_npids
    sites = self.sites
    allocated = LocationNpid.where(["location_id in (?)", sites]).count
  end
  
  def assigned_npids
    sites = self.sites
    assigned = LocationNpid.where(["location_id in (?) and assigned = 1", sites]).count
  end

  def sites
    sites = DistrictSite.where(["district_id in (?)", self.location_id]).map(&:site_id)
  end
  
end
