class Api::V1::TroubleshootingController <  ActionController::Base
  layout "application" 

  skip_before_action :verify_authenticity_token, only: [:troubleshoot]

  def index
    @result = params[:result]
  end

  def sync_status
  end

  def logs
  end

  def network_check
  end

  def troubleshoot
    @error_type = params[:error_type_search]
    Rails.logger.info "Params received: #{params.inspect}"

    begin 
      output =  Troubleshooter.select_solution(@error_type)
      redirect_to troubleshooting_path(result: "Executed => #{@error_type}. [Output]: #{output}")
    rescue => e
      redirect_to troubleshooting_path(result: "Error: #{e.message}")
    end
  end
  
end