class Api::V1::LocationController < ApplicationController
    
  def find
    location = Location.where(location_id: params[:location_id]).or(Location.where(couchdb_location_id: params[:location_id]))
    location = location.blank? ? [] : location.first
    render plain: location.to_json
  end
  
  def list_assigned_locations
    render plain: LocationService.list_assigned_locations.to_json
  end
  
  def npids_assigned
    
    render plain: NpidService.npids_assigned(params).to_json
    
  end
  
  def total_allocated_npids
    
    render plain: NpidService.total_allocated_npids(params).to_json
    
  end

  def get_locations
    render plain: LocationService.get_locations(params).to_json
  end

end
