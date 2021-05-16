require "syncing_service/sync_service"

class Api::V1::SyncController < ApplicationController

  def pull_updates
  	records_changed = SyncService.person_changes(update_params[:site_id], update_params[:pull_seq])

  	render json: records_changed
  end

  def pushed_updates
    update = SyncService.update_records(push_params)
    if update
      render json: update, status: 200
    else
      render json: {status: 402}
    end
  end


  private

  def update_params
    params.permit(:site_id,:pull_seq)
  end

  def push_params
    params.permit(:id,:last_name,
                              :first_name,
                              :middle_name,
                              :gender,
                              :current_village,
                              :current_traditional_authority,
                              :current_district,
                              :home_village,
                              :home_traditional_authority,
                              :home_district,
                              :birthdate,
                              :birthdate_estimated,
                              :person_uuid ,
                              :npid,
                              :date_registered,
                              :last_edited,
                              :location_created_at,
                              :location_updated_at,
                              :creator
                              )
  end
end
