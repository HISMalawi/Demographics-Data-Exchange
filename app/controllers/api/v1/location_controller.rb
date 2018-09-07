class Api::V1::LocationController < ApplicationController
  def find
    render json: LocationService.find_location(params[:location_id])
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
