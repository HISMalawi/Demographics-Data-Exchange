class Api::V1::FootprintController < ApplicationController
  def update_footprint
    footprint = FootPrintService.create(foot_params)
    render json: footprint
  end

  def by_category
    footprint = FootPrintService.by_category(params[:category])
    render json: footprint
  end

  private
   def foot_params
    params.require([:user_id,:person_uuid,:program_id,:location_id,:encounter_datetime])
    params.permit(:user_id,:person_uuid,:program_id,:location_id,:encounter_datetime)
    {user_id: params[:user_id],person_uuid: params[:person_uuid][:identifier],program_id: params[:program_id], location_id: params[:location_id],
      encounter_datetime: params[:encounter_datetime]}
   end

end
