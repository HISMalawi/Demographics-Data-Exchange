class Api::V1::UserController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login]

  def login
    authenticate params[:username], params[:password]
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
    location_id = Location.find_by_location_id(params[:location]).id
    user = User.create(username: params[:username],
                       email: params[:email], password: params[:password],
                       location_id: location_id)
    if user
      response = {status: 200, message: "User created successfully"}
      render json: response, status: :created
    else
      render json: user.errors, status: :bad
    end
  end

  def index
    #render plain: {name: "john"}.to_json
    render file: Rails.root.join("public", "index.html")
  end

  def verify_token
    token_status = HashWithIndifferentAccess.new(
      JWT.decode(params[:token], Rails.application.secrets.secret_key_base)[0]
    ) rescue []

    if token_status.blank?
      return render json: {message: "Failed"}, status: 401
    else
      return render json: {message: "Successful"}
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
               message: "Login Successful",
             }
    else
      render json: {error: command.errors}, status: :unauthorized
    end
  end
end
