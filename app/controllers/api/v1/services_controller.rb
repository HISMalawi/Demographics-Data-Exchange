class Api::V1::ServicesController < ActionController::Base
  layout "application"
  skip_before_action :verify_authenticity_token, only: [:manage]

  def index 
    @services = ["dde4", "redis-server", "dde4_sidekiq", "mysql"]
    @actions  = ["start", "stop", "restart", "status"]
    @result   = params[:result]

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
      redirect_to services_path(result: "#{@action.capitalize} executed for #{@service}. Output: #{output}")
    rescue => e
      redirect_to services_path(result: "Error: #{e.message}")
    end
  end 
end