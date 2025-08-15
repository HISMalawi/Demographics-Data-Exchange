class Api::V1::TroubleshootingController <  ActionController::Base
  layout "application" 

  def index
  end

  def sync_status
  end

  def logs
  end

  def network_check
  end

  def troubleshoot
    error_type = params[:error_type_search]
    Rails.logger.info "Params received: #{params.inspect}"

  
    #render json: {
    #  error_type: error_type,
    #  description: info[:description],
    #  steps: info[:steps]
    #}
  end

 


  
end