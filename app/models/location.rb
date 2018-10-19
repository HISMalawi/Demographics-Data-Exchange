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

  def online?
    status        = "OFFLINE"
    last_updates  = ""
    npids     = LocationNpid.where(location_id: self.id)
    unless npids.blank?
      updated_in_people = Person.where(location_created_at: self.id).select(["*, MAX(updated_at)"]).limit(1).first.updated_at
      unless updated_in_people.blank?
        last_updates  = updated_in_people.to_date 
      
        if (Date.today.to_date == updated_in_people.to_date)
          status        = "ONLINE"
        end
      
      end

      return status, last_updates
    end
    
    return status, last_updates
  end
  
end
