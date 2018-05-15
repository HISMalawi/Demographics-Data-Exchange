class Api::V1::UserController < ApplicationController
	skip_before_action :authenticate_request, only: %i[login]

	def login
		authenticate params[:username], params[:password]
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
	
	def add_user
	  # POST /add_user
	  couchdb_location_id = CouchdbLocation.get_location_by_name(params[:location]).id
	  mysql_location_id = Location.get_location_by_name(params[:location]).id
	  
	  couchdb_user  = CouchdbUser.create(username: params[:username], 
	    location_id: couchdb_location_id,
      email: params[:email], password_digest: 'password_digest') #password_digest will be updated later

    user  = User.create(username: params[:username], couchdb_user_id: couchdb_user.id, 
    email: couchdb_user.email, password: params[:password], location_id: mysql_location_id)
    
    couchdb_user.update_attributes(password_digest: user.password_digest)

   if user
    response = { message: 'User created successfully'}
    render json: response, status: :created 
   else
    render json: user.errors, status: :bad
   end 
	end

	private

	def user_params
		params.permit(:username, :password)
	end

	def authenticate(username, password)
		command = AuthenticateUser.call(username, password)

		if command.success?
			render json: {
				access_token: command.result,
				message: 'Login Successful'
			}
		else
			render json: { error: command.errors }, status: :unauthorized
		end
	end


end
