# frozen_string_literal: true

# Parent controller
class ApplicationController < ActionController::API
  before_action :authenticate_request, except: %i[index verify_token refresh_dashboard whitelist_ip_address]
  before_action :authorize_system_user, only: %i[ whitelist_ip_address]
  after_action  :update_socket_dashboard, only: %i[pushed_updates pushed_updates_new pushed_footprints]
  after_action  :update_location_npids, only: %i[pushed_updates pushed_updates_new assign_npids]

  attr_reader :current_user

  include ExceptionHandler

   # [...]
	private
	def authenticate_request
		@current_user = AuthorizeApiRequest.call(request.headers).result
		User.current = @current_user
		render json: { error: 'Not Authorized' }, status: 401 unless @current_user
	end

	def authorize_system_user
    	token = request.headers[:Authorization]
    	response = JSON.parse(UserManagement::ApplicationController.authorized(token))
    	return render json: {status: 403, message: 'User not authorized or token expired'}, status: 403 if response['status'] == 403
    	return render json: {status: 401, message: 'Invalid username or password'}, status: 401 if response['status'] == 401
  	end

	def update_socket_dashboard
	   	DashboardSocketDataJob.perform_later
	end

	def update_location_npids
	  LocationNpidJob.perform_later
	end
end
