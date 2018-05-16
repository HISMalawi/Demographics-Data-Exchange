class Api::V1::FootprintController < ApplicationController
  def update_footprint
    footprint = FootPrintService.create(params)
    render plain: footprint.to_json
  end
end
