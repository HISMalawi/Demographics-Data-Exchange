require "syncing_service/sync_service"

class Api::V1::SyncController < ApplicationController

  def pull_updates_new
  	records_changed = SyncService.person_changes_new(update_params)

  	render json: records_changed
  end

  def pull_updates
    records_changed = SyncService.person_changes_updates(update_params)

    render json: records_changed
  end

  def pushed_updates
    update = SyncService.update_records_updates(push_params)
    if update
      render json: update, status: 200
    else
      render json: {status: 402}
    end
  end

   def pushed_updates_new
    update = SyncService.update_records_new(push_params)
    if update
      render json: update, status: 200
    else
      render json: {status: 402}
    end
  end

  def pull_npids
    npids = SyncService.pull_npids(npid_params)
    render json: npids
  end


  private

  def update_params
    params.require([:site_id,:pull_seq])
  end

  def npid_params
    params.require([:site_id,:npid_seq])
  end

  def push_params
    params.permit(:id,
                  :last_name,
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
                  :creator,
                  :home_ta,
                  :ancestry_village,
                  :ancestry_ta,
                  :ancestry_district,
                  :voided,
                  :voided_by,
                  :date_voided,
                  :void_reason,
                  :first_name_soundex,
                  :last_name_soundex,
                  :update_seq
                  )
  end
end
