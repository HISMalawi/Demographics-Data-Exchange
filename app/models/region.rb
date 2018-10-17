class Region < ApplicationRecord
  
  def total_npids
    sites = self.sites
    allocated = LocationNpid.where(["location_id in (?)", sites]).count
  end
  
  def assigned_npids
    sites = self.sites
    assigned = LocationNpid.where(["location_id in (?) and assigned = 1", sites]).count
  end

  def districts
    districts = RegionDistrict.where(region_id: self.id).map(&:district_id)
    Location.where(["location_id in (?)", districts])
  end

  def sites
    districts = RegionDistrict.where(region_id: self.id).map(&:district_id)
    sites = DistrictSite.where(["district_id in (?)", districts]).map(&:site_id)
  end
end