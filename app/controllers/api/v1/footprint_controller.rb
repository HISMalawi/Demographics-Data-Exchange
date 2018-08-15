class Api::V1::FootprintController < ApplicationController
  def update_footprint
    footprint = FootPrintService.create(params)
    render json: footprint
  end
end
