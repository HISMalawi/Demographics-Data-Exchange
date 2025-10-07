class Api::V1::ServicesController < ActionController::Base
  layout "application"
  skip_before_action :verify_authenticity_token, only: [:manage]

  def index
    
  end

  def manage
    @service = params[:service]
    @action  = params[:action_name]

    begin
      output = ServiceManager.run(@action, @service)
      @status_value = output.downcase.include?("running") ? "running" :
                      output.downcase.include?("stopped") ? "stopped" : "unknown"
      @result = "#{@action.capitalize} executed for #{@service}. Output: #{output}"
      @status = "ok"

      respond_to do |format|
        format.json { render json: { output: output, status_value: @status_value, status: status } }
      end

    rescue => e
      @result = "Error: #{e.message}"
      @status = "error"
      @status_value = "unknown"
      
      respond_to do |format|
        format.json { render json: { output: @result, status: @status, status_value: @status_value } }
      end

    end
  end
end