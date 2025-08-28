class Api::V1::TroubleshootingController < ActionController::Base
  layout "application"
  skip_before_action :verify_authenticity_token, only: [:troubleshoot, :reset_sync_credentials]

  def index
    @result = params[:result]
    @result_status = params[:status]
  end

  def troubleshoot
    @error_type = params[:error_type_search]
    Rails.logger.info "Params received: #{params.inspect}"

    begin 
      result = troubleshooting_service.select_solution(@error_type)

      if result.is_a?(Hash)
        @result_status = result[:status]
        @result_message = result[:message]
      else
        @result_status = :ok
        @result_message = result.to_s
      end


      redirect_to troubleshooting_path(result: @result_message, status: @result_status)
    rescue => e
      redirect_to troubleshooting_path(result: "Error: #{e.message}", status: :error)
    end
  end

  def reset_sync_credentials
    begin 
      username = params[:username]
      password = params[:password]
      location_id = params[:location_id]

      sync_config_updated = troubleshooting_service.reset_sync_credentials(
                              username:,
                              password:,
                              location_id:
                              )

      if sync_config_updated
        redirect_to troubleshooting_path(result: "Output: Sync Credentials updated succesfully", status: :error)
      else
        redirect_to troubleshooting_path(result: "Error: #{e.message}", status: :error)
      end
      
    rescue => e
      redirect_to troubleshooting_path(result: "Error: #{e.message}", status: :error)
    end
  end

  private 

  def troubleshooting_service
    Troubleshooter.new
  end
end