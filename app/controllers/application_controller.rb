# frozen_string_literal: true

# Parent controller
class ApplicationController < ActionController::API
  before_action :authenticate_request, except: %i[index verify_token refresh_dashboard]
  after_action  :update_socket_dashboard, only: %i[pushed_updates pushed_updates_new pushed_footprints]
  after_action  :update_location_npids, only: %i[pushed_updates pushed_updates_new assign_npids]

  attr_reader :current_user

  include ExceptionHandler

	def update_socket_dashboard
	   	DashboardSocketDataJob.perform_later
	end

	def update_location_npids
	  LocationNpidJob.perform_later
	end
end
