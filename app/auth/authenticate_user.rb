require 'rest-client'

class AuthenticateUser
  prepend SimpleCommand
  attr_accessor :username, :password, :user_type

  #this is where parameters are taken when the command is called
  def initialize(username, password, user_type)
    @username = username
    @password = password
    @user_type = user_type
  end
  
  #this is where the result gets returned
  def call
    type = user_type.presence || "proxy"

    if type == "proxy"
      JsonWebToken.encode(user_id: user.id, user_location_id: user.location_id) if user
    elsif type == "system"
      authorize_system_user
    else
      errors.add :user_authentication, 'User type does not exist'
    end 

  end

  private

  def user
    user = User.find_by_username(username)
    return user if user && user.authenticate(password)

    errors.add :user_authentication, 'Invalid credentials'
    nil
  end

  def authorize_system_user

    host = Rails.application.routes.default_url_options[:host]
    base_url = "#{host}/v1/token"

    payload = { username: username, password: password }.to_json

    begin
      response = RestClient.post( base_url, payload,
                                { content_type: :json, accept: :json })

      parsed_response = JSON.parse(response.body)

      if parsed_response['status'] == 403
        errors.add :user_authentication, 'User not authorized or token expired'
      elsif parsed_response['status'] == 401
        errors.add :user_authentication, 'Invalid username or password'
      else
        return parsed_response
      end
    rescue RestClient::ExceptionWithResponse => e
      errors.add :user_authentication, 'Authentication failed' 
    rescue JSON::ParserError => e
      errors.add :user_authentication, 'Failed to parse response' 
    end

    nil
  end 
end
