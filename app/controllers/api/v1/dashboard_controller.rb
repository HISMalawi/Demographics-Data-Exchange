# frozen_string_literal: true
class Api::V1::DashboardController < ApplicationController
  def new_registrations
    registrations = PersonDetail.where('date(date_registered) = date(last_edited)').count

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
end