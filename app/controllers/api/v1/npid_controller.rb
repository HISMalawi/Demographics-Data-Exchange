class Api::V1::NpidController < ApplicationController
  after_action :update_npid_pool_balance

  def assign_npids
    npids = NpidService.assign(params[:limit], current_user, params[:location_id])
    render json: npids
  end

  def allocate_npids
    npids = NpidService.allocate_npids(params[:location_id], params[:count])
    render json: npids
  end

  private
  def update_npid_pool_balance
    NpidPoolJob.perform_later
  end
end
