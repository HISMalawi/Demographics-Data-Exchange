require "yaml"
require "net/http"
require "uri"
require "socket"

class Troubleshooter
  CONFIG_FILE_PATH = Rails.root.join("config", "database.yml")

  def initialize
    @config = load_config
  end

  def select_solution(error_type) 
    case error_type
    when "resolve_sync_configs"
      resolve_sync_configs
    when "detect_footprint_conflicts"
      detect_footprint_conflicts
    when
      { status: :unknown, message: "Unknown error type" }
    end
  end

  def reset_sync_credentials(username:, password:, location_id:)
    config = load_config
    sync_config = config[:dde_sync_config] || config["dde_sync_config"]

    if sync_config
      sync_config[:username]   = username
      sync_config[:password]   = password
      sync_config[:location_id] = "#{username}_#{location_id}"

      save_config(config)
      { status: :ok, message: "Sync credentials updated successfully." }
    else 
      raise "Sync configuration not found"
    end 
  end

  def detect_footprint_conflicts
    footprint_summary = FootPrint.group(:location_id).count

    locations_with_footprints = footprint_summary.select { |_location_id, count| count > 0 }

    if locations_with_footprints.size > 1
      ip_address = Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address
      matching_locations = Location.where(ip_address: ip_address)

      if matching_locations.count > 1
        raise "🚨 <strong>Conflict Detected:</strong> The IP address <strong>#{ip_address}</strong> is linked to <strong>multiple locations</strong>. Please verify your network configuration or update the location records."
      elsif matching_locations.exists?
        current_location_id = matching_locations.pick(:location_id)
        updated_records_count = FootPrint.update_all(location_id: current_location_id)

        if updated_records_count.positive?
          return {
            status: :ok,
            message: "✅ <strong>Footprints successfully reassigned</strong> to location ID <strong>#{current_location_id}</strong> (IP: <strong>#{ip_address}</strong>).",
            details: {
              updated_records: updated_records_count,
              involved_locations: locations_with_footprints.keys
            }
          }
        else
          raise "⚠️ <strong>Update Failed:</strong> Could not reassign footprints for IP <strong>#{ip_address}</strong>. Please check database integrity or permissions."
        end
      else
        raise "🚨 <strong>Unresolved Footprint Conflict:</strong> Found <strong>#{locations_with_footprints.size}</strong> different locations with footprints, but the current IP address <strong>(#{ip_address})</strong> is not registered in the <strong>locations</strong> table. Unable to auto-resolve footprints."
      end
    else
      {
        status: :ok,
        message: "✅ <strong>Footprints resolved successfully</strong> — all records belong to a single valid location.",
        details: locations_with_footprints
      }
    end
  end

  def attempt_sync_job_unlocking
    unless sync_job_running?
      File.delete(LOCK_FILE_PATH) if File.exist?(LOCK_FILE_PATH)
      true
    else
      false
    end 
  end 

  private

  def resolve_sync_configs
    sync_config = get_sync_config
    return { status: :error, message: "Sync configuration not found" } unless sync_config

    username  = sync_config[:username] || sync_config["username"]
    password  = sync_config[:password] || sync_config["password"]

    return { status: :auth_failed, message: "Sync username and password not available" } unless username && password

    updated = false

    # Ensure correct protocol/host 
    if (sync_config[:protocol] || sync_config["protocol"]).to_s.downcase != "https"
      sync_config[:protocol] = "https"
      updated = true
    end

    if (sync_config[:host] || sync_config["host"]) != "ddedashboard.hismalawi.org"
      sync_config[:host] = "ddedashboard.hismalawi.org"
      updated = true
    end

    save_config(sync_config) if updated
    return { status: :ok, message: "Sync configuration updated with correct protocol/host" } if updated

    # Try authentication
    remote_success = authenticate_remote(username, password)
    local_success  = authenticate_local(username, password)

    # All good if both auths succeed
    return { status: :ok, message: "✅ Sync authentication succeeded (proxy & master)" } if remote_success && local_success

    # Auto-reset password using default user
    new_password = SecureRandom.hex(12)
    reset_result = reset_sync_password_via_default_user(username, new_password)
  

    if reset_result[:status] == :ok
      sync_config[:password] = new_password
      save_config(sync_config)

      # Retry authentication
      remote_success = authenticate_remote(username, new_password)
      local_success = authenticate_local(username, new_password)


      if remote_success && local_success
        { status: :ok, message: "✅ Sync password automatically reset and authentication succeeded" }
      else
        { status: :auth_failed, message: "⚠️ Password reset attempted but authentication still failed. Manual intervention needed." }
      end
    else
      { status: :auth_failed, message: "⚠️ Automatic password reset failed: #{reset_result[:message]}. Please reset manually." }
    end 
  end

  def authenticate_remote(username, password)
    port = ENV.fetch("PORT", 8050)
    uri =  URI("http://localhost:#{port}/v1/login?username=#{username}&password=#{password}")
    response = Net::HTTP.post(uri, "")
    response.is_a?(Net::HTTPSuccess)
  rescue
    false
  end

  def authenticate_local(username, password)
     port = ENV.fetch("PORT", 8050)
     uri = URI("http://localhost:#{port}/v1/login?username=#{username}&password=#{password}")
     response = Net::HTTP.post(uri, "")
     response.is_a?(Net::HTTPSuccess)
  rescue
    false
  end

  def get_sync_config
    config = load_config
    config[:dde_sync_config] || config["dde_sync_config"]
  end

  def load_config
    YAML.load_file(CONFIG_FILE_PATH, aliases: true)
  end

  def save_config(new_sync_config)
    full_config = load_config
    full_config[:dde_sync_config] ||= {}
    full_config[:dde_sync_config].merge!(new_sync_config.symbolize_keys)

    File.open(CONFIG_FILE_PATH, "w") do |f|
      f.write(full_config.to_yaml)
    end
  end

  def reset_sync_password_via_default_user(sync_username, new_password)

    admin_username = Rails.application.credentials.admin_username
    admin_password = Rails.application.credentials.admin_password

    unless admin_username && admin_password
      return { status: :error, message: "Admin credentials missing in Rails credentials" }
    end

    login_uri = URI("http://localhost:8050/v1/login")
    login_request = Net::HTTP::Post.new(login_uri)
    login_request.set_form_data(username: admin_username, password: admin_password)

    login_response = Net::HTTP.start(login_uri.hostname, login_uri.port) do |http|
      http.request(login_request)
    end

    unless login_response.is_a?(Net::HTTPSuccess)
      return { status: :error, message: "Failed to login as default admin: #{login_response.body}" }
    end

    token = JSON.parse(login_response.body)["access_token"]
    unless token
      return { status: :error, message: "Login succeeded but no access token returned" }
    end

    sync_user = User.find_by(username: sync_username)
    return { status: :error, message: "Sync user not found locally" } unless sync_user

    sync_user.password = new_password
    unless sync_user.save
      return { status: :error, message: "Failed to update local password: #{sync_user.errors.full_messages.join(', ')}" }
    end

    update_uri = URI("http://localhost:8050/v1/update_password")
    update_request = Net::HTTP::Post.new(update_uri)
    update_request["Authorization"] = "Bearer #{token}"
    update_request.set_form_data(username: sync_username, password: new_password)

    update_response = Net::HTTP.start(update_uri.hostname, update_uri.port) do |http|
      http.request(update_request)
    end

    if update_response.is_a?(Net::HTTPSuccess)
      { status: :ok, message: "Password reset successfully locally and remotely" }
    else
      { status: :error, message: "Password reset locally but failed remotely: #{update_response.body}" }
    end
  rescue => e
    { status: :error, message: e.message }
  end

  def sync_job_running?
    Sidekiq::Workers.new.any? do |process_id, thread_id, work|
      work["payload"]["class"] == SyncJob
    end
  end


end