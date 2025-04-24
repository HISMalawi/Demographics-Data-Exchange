require 'rest-client'
require 'json'

class ZohoService
  ZOHO_TOKEN_URL = 'https://accounts.zoho.com/oauth/v2/token'.freeze
  ZOHO_REDIRECT_URI = 'https://www.zoho.com'.freeze
  ZOHO_API_URL = 'https://egpafemr.sdpondemand.manageengine.com/api/v3/requests'.freeze

  #SDPOnDemand.requests.ALL

  def initialize(client_id: ENV['ZOHO_CLIENT_ID'], client_secret: ENV['ZOHO_CLIENT_SECRET'], auth_code: ENV['ZOHO_AUTH_CODE'])
    @client_id = client_id
    @client_secret = client_secret
    @auth_code = auth_code
  end

  def get_access_token
    response = RestClient.post(
      ZOHO_TOKEN_URL,
      {
        code: @auth_code,
        client_id: @client_id,
        client_secret: @client_secret,
        redirect_uri: ZOHO_REDIRECT_URI,
        grant_type: 'authorization_code'
      },
      { content_type: 'application/x-www-form-urlencoded' }
    )
    
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    handle_error(e)
  end

  def send_request(subject: "Test Ticket from DDE Rails")
    payload = {
      input_data: {
        request: {
          subject: subject
        }
      }
    }

    response = RestClient.post(
      ZOHO_API_URL,
      payload.to_json,
      {
        Authorization: "Zoho-oauthtoken #{ENV['ZSDP_OAUTH_TOKEN']}",
        content_type: 'application/json',
        accept: 'application/vnd.manageengine.sdp.v3+json'
      }
    )

    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    handle_error(e)
  end

  private

  def handle_error(error)
    puts "API Error: #{error.response}"
    { error: error.response }
  end
end
