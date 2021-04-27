require "syncing_service/sync_service"

class Api::V1::SyncController < ApplicationController
  
  def pull_updates
  	records_changed = SyncService.person_changes(params[:site_id],params[:pull_seq])

  	render json: records_changed
  end


  private 

  def update_params
    params.require(:site_id, :pull_seq)
  end
end