class Api::V1::UserController < ApplicationController
	skip_before_action :authenticate_request, only: %i[login]

	def login
		authenticate params[:email], params[:password]
	end

	def register
		# POST /register
		@user = User.create(user_params)
	 if @user.save
		response = { message: 'User created successfully'}
		render json: response, status: :created 
	 else
		render json: @user.errors, status: :bad
	 end 
	end

	private

	def user_params
		params.permit(:email, :password)
	end

	def authenticate(email, password)
		command = AuthenticateUser.call(email, password)

		if command.success?
      update_session(email, command.result)
			render json: {
				access_token: command.result,
				message: 'Login Successful'
			}
		else
			render json: { error: command.errors }, status: :unauthorized
		end
	end

  def update_session(email, token)
    user = User.where(email: email).first
    session_record = Session.where(user_id: user.id)

    unless session_record.blank?
      session_record.first.update_attributes(token: token)
    else
      Session.create(token: token, user_id: user.id)
    end

  end

end
