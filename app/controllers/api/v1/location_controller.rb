class Api::V1::LocationController < ApplicationController
    
  def find
    location = Location.where(location_id: params[:location_id]).or(Location.where(couchdb_location_id: params[:location_id]))
    location = location.blank? ? [] : location.first
    render plain: location.to_json
  end

end
