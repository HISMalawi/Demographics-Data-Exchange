class Api::V1::UserController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login]

  def login
    authenticate(params[:username], params[:password], params[:user_type])
  end

  def register
    # POST /register
    @user = User.create(user_params)
    if @user.save
      response = {message: "User created successfully"}
      render json: response, status: :created
    else
      render json: @user.errors, status: :bad
    end
  end

  def add_user
    # POST /add_user
     true if Integer(params[:location]) rescue return render json: {msg: 'Please provide an integer for location'}, status: :unprocessable_entity

    location_id = Location.find_by_location_id(params[:location]).id
    user = User.create(username: params[:username],
                       email: params[:email], password: params[:password],
                       location_id: location_id)
    if user.save
      response = {status: 200, message: "User created successfully"}
      render json: response, status: :created
    else
      render json: user.errors, status: :ok
    end
  end

  def update_password
    user = User.find_by(username: params[:username])

    unless user
      return render json: { status: 404, message: "User not found" }, status: :not_found
    end

    new_password = params[:password]

    if new_password.blank?
      return render json: { status: 422, message: "Password cannot be blank" }, status: :unprocessable_entity
    end

    if user.update(password: new_password)
      render json: { status: 200, message: "Password updated successfully" }, status: :ok
    else
      render json: { status: 422, message: "Failed to update password", errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    #render plain: {name: "john"}.to_json
    render file: Rails.root.join("public", "index.html")
  end

  def verify_token
    token_status = JsonWebToken.decode(params[:token]) rescue []

    if token_status.blank?
      return render json: {message: "Failed"}, status: 401
    else
      return render json: {message: "Successful"}, status: :ok
    end
  end

  private

  def user_params
    params.permit(:username, :password, :user_type)
  end

  def authenticate(username, password, user_type)
    command = AuthenticateUser.call(username, password, user_type)

    if command.success?
      render json: {
              access_token: command.result,
              message: "Login Successful",
             }
    else
      render json: {error: command.errors}, status: :unauthorized
    end
  end
end
