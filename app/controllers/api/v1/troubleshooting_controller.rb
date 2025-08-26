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
      result = Troubleshooter.select_solution(@error_type)

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
    username = params[:username]
    password = params[:password]
    location_id_param = params[:location_id]

    config_file = Rails.root.join("config", "database.yml")
    config = YAML.load_file(config_file, aliases: true)
    sync_config = config[:dde_sync_config] || config["dde_sync_config"]

    if sync_config
      # Update symbol keys
      sync_config[:username] = "#{username}_#{location_id_param}"
      sync_config[:password] = password

      File.open(config_file, "w") { |f| f.write(config.to_yaml) }
      render json: { status: "success", message: "Sync credentials updated successfully." }
    else
      render json: { status: "error", message: "Sync configuration not found." }
    end
  rescue => e
    render json: { status: "error", message: e.message }
  end
end