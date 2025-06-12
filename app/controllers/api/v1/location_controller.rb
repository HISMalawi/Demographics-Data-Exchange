class Api::V1::LocationController < ApplicationController

  def index 
    render json: Location.where(voided: false).all
  end 


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

  def get_regions
    render json: LocationService.get_regions
  end

  def regional_stats
    render json: LocationService.fetch_regional_stats
  end

  def update_location_field
    field = params[:field]
    couchdb_location  = CouchdbLocation.find(params[:location_id])
    mysql_location    = Location.where(couchdb_location_id: params[:location_id]).first
    case field
      when "name"
        couchdb_location.update_attributes(name: "#{params[:value]}")
        mysql_location.update_attributes(name: "#{params[:value]}")
      when "code"
        couchdb_location.update_attributes(code: "#{params[:value]}")
        mysql_location.update_attributes(code: "#{params[:value]}")
      when "ip_address"
        couchdb_location.update_attributes(ip_address: "#{params[:value]}")
        mysql_location.update_attributes(ip_address: "#{params[:value]}")
    end
    #couchdb_location.update_attributes(eval(t))
    #render json: couchdb_location
    #<CouchdbLocation name: nil, description: nil, latitude: "-13.8898", longitude: "33.80487", voided: nil, void_reason: nil, parent_location: "f79a0d44a0e921e79b6205bb8fe05a08", code: nil, creator: "f79a0d44a0e921e79b6205bb8fe22e83", updated_at: 2018-10-09 13:22:06 UTC, created_at: 2018-10-08 13:31:39 UTC, _id: "1200f9a4d2c0a8a52396511c67163673", _rev: "3-a9a77ab19107a2e11d543bea2d66a958", type: "CouchdbLocation">
  end

  def sync_info
    render json: LocationService.sync_info
  end
end
