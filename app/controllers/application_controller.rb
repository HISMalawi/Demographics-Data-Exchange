class ApplicationController < ActionController::API
	before_action :authenticate_request, except: %i[index, verify_token, refresh_dashboard]
	after_action  :update_socket_dashboard, only: [:pushed_updates, :pushed_updates_new, :pushed_footprints]
	after_action  :update_location_npids, only: [:pushed_updates, :pushed_updates_new, :assign_npids]
	
	attr_reader :current_user

	include ExceptionHandler

	# [...]
	private
	def authenticate_request
		@current_user = AuthorizeApiRequest.call(request.headers).result
		User.current = @current_user
		render json: { error: 'Not Authorized' }, status: 401 unless @current_user
	end

	def update_socket_dashboard
	  unless File.exist?(Rails.root.join('tmp', 'dashboard_stats.lock'))
		FileUtils.touch(Rails.root.join('tmp/dashboard_stats.lock'))
	  	DashboardSocketDataJob.perform_later
	  end
	end

	def update_location_npids
	  LocationNpidJob.perform_later
	end
end

