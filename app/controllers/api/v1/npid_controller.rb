class Api::V1::NpidController < ApplicationController

  def assign_npids
    npids = NpidService.assign(params[:limit], current_user)
    render plain: npids.to_json
  end

end
