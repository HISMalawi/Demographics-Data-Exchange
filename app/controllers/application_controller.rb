class ApplicationController < ActionController::API
	before_action :authenticate_request, except: %i[index, verify_token]
	after_action  :update_socket_dashboard
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
	  DashboardSocketDataJob.perform_later 
	end

end

