class Api::V1::TroubleshootingController < ActionController::Base
  layout "application"
  skip_before_action :verify_authenticity_token, only: [:troubleshoot, 
                                                        :reset_sync_credentials,
                                                        :reset_location_id ]

  def index
    @result = params[:result]
    @result_status = params[:status]
  end

  def troubleshoot
    @error_type = params[:error_type]
    Rails.logger.info "Params received: #{params.inspect}"

    begin
      result = troubleshooting_service.select_solution(@error_type)

      response_data = 
        if result.is_a?(Hash)
          { 
            error_type: @error_type, 
            status: result[:status], 
            message: result[:message] 
          }
        else
          { 
            error_type: @error_type, 
            status: result.respond_to?(:status) ? result.status : :unknown, 
            message: result.to_s 
          }
        end

      respond_to do |format|
        format.json { render json: response_data }    # used by JS fetch
      end
    rescue => e
      respond_to do |format|
        format.json { render json: { status: "error", message: e.message }, status: :internal_server_error }
      end
    end
  end

  def reset_sync_credentials
    begin
      username    = params[:username]
      password    = params[:password]
      location_id = params[:location_id]

      sync_config_updated = troubleshooting_service.reset_sync_credentials(
        username: username,
        password: password,
        location_id: location_id
      )

      if sync_config_updated
        redirect_to troubleshooting_path(result: "Output: Sync Credentials updated successfully", status: :success)
      else
        redirect_to troubleshooting_path(result: "Error: Failed to update sync credentials", status: :error)
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