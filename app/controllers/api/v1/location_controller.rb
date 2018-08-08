class Api::V1::LocationController < ApplicationController
  def find
    location = Location.where(location_id: params[:location_id]).or(Location.where(couchdb_location_id: params[:location_id]))
    location = location.blank? ? [] : location.first
    render json: location
  end

  def list_assigned_locations
    render json: LocationService.list_assigned_locations
  end

  def npids_assigned
    render json: NpidService.npids_assigned(params)
  end

  def total_allocated_npids
    render json: NpidService.total_allocated_npids(params)
  end

  def get_locations
    render json: LocationService.get_locations(params)
  end
end
