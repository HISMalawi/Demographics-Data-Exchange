class Api::V1::ServicesController < ActionController::Base
  layout "application"
  skip_before_action :verify_authenticity_token, only: [:manage]

  def index
    @services = ["dde4", "redis-server", "dde4_sidekiq", "mysql"]
    @actions  = ["start", "stop", "restart", "status"]

    @service_status = {}
    @services.each do |service|
      begin
        output = ServiceManager.run("status", service)
        @service_status[service] =
          output.downcase.include?("running") ? "running" :
          output.downcase.include?("stopped") ? "stopped" : "unknown"
      rescue => e
        @service_status[service] = "unknown"
      end
    end
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
        format.json { render json: { output: @result, status: @status, status_value: @status_value } }
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