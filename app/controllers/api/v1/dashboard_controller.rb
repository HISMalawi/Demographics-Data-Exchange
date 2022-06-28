# frozen_string_literal: true
class Api::V1::DashboardController < ApplicationController
  def new_registrations
    registrations = PersonDetail.where('date(date_registered) = date(now())').count

    if registrations
      render json: { total_new_registrations: registrations }, status: :ok
    else
      render json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def new_registrations_by_site
    registrations = DashboardService.new_reg_by_site
    if registrations
      render json: { total_new_registrations_by_site: registrations }, status: :ok
    else
      ender json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def new_reg_past_30
    registrations = DashboardService.new_reg_past_30
    if registrations
      render json: { total_new_reg_by_site_past_30: registrations }, status: :ok
    else
      ender json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def client_movement
    movement = DashboardService.client_movements
    if movement
      render json: { client_movement: movement }, status: :ok
    else
      ender json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def npid_status
    npid_state = DashboardService.npids
    if npid_state
      render json: { npid_status: npid_state }, status: :ok
    else
      render json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def connected_sites
    connected_state = DashboardService.connected_sites
    if connected_state
      render json: { connected_sites: connected_state }, status: :ok
    else
      render json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def site_activity
    site_activity = DashboardService.site_activities
    if site_activity
      render json: { site_activity: site_activity }, status: :ok
    else
      render json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def location_npid_status
    npid_state = DashboardService.location_npids(location_npid_status_params[:location_id])
    if npid_state
      render json: { npid_status: npid_state }, status: :ok
    else
      render json: { error: 'something went wrong' }, status: :unprocessable_entity
    end
  end

  def refresh_dashboard
      data = DashboardStat.where(:name => "dashboard_stats")
      ActionCable.server.broadcast('dashboard_channel', message: data.first.value.to_json)
      render json: {message: 'Initilized Dashboard Refresh'}, status: :ok 
  end

  private
    def location_npid_status_params
      params.require(:location_id)
      params.permit(:location_id)
    end
end
