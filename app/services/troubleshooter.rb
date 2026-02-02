require "yaml"
require "net/http"
require 'rest-client'
require "uri"
require "securerandom"

class Troubleshooter
  include NetworkHelper

  CONFIG_FILE_PATH = Rails.root.join("config", "database.yml")
  LOCK_FILE_PATH = "/tmp/dde_sync.lock"
  EMR_APPLICATION_CONFIG_FILE = "/var/www/EMR-API/config/application.yml"

  def initialize
    @config = load_config
  end

  def select_solution(error_type) 
    case error_type
    when "unlock_sync_job"
      unlock_sync_job
    when "resolve_sync_configs"
      resolve_sync_configs
    when "detect_footprint_conflicts"
      detect_footprint_conflicts
    when "resolve_program_credentials"
      reset_program_user_credentials
    else
      { status: :unknown, message: "Unknown error type" }
    end
  end

  def reset_program_user_credentials
    program_credentials = get_emr_program_credentials

    results = program_credentials.map do | program_credential|
      local_success = authenticate_local(program_credential[:username], program_credential[:password])

      if local_success
        program_credential[:authentication_status] = "passed"
      else
        program_credential[:authentication_status] = "failed"
      end 
      
      # Remove password before returning
      program_credential.except(:password)
    end 
    
    { status: :ok, message: results}
    
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
      begin
        location = User.non_default_location! # this enforces one valid non-default user location
      rescue StandardError => e
        raise "<strong>Footprint Conflict:</strong> #{e.message}"
      end

      if location
        updated_records_count = FootPrint.update_all(location_id: location.location_id)
        if updated_records_count.positive?
          {
            status: :ok,
            message: "<strong>Footprints reassigned</strong> to <strong>#{location.name}</strong>.",
            details: {
              updated_records: updated_records_count,
              involved_locations: locations_with_footprints.keys
            }
          }
        else
          raise "<strong>Update Failed:</strong> Could not reassign footprints for <strong>#{location.name}</strong>."
        end
      else
        raise "<strong>Unresolved Conflict:</strong> Found multiple locations but no valid non-default user location available."
      end

    else
      {
        status: :ok,
        message: "<strong>Footprints resolved successfully</strong> — all records belong to a single valid location.",
        details: locations_with_footprints
      }
    end
  end

  def unlock_sync_job
    if sync_job_running?
      { status: :ok, message: "Sync is currently running" }
    elsif File.exist?(LOCK_FILE_PATH)
      File.delete(LOCK_FILE_PATH)
      { status: :ok, message: "Removed sync lock file" }
    else
      { status: :ok, message: "Sync lock already removed" }
    end
  end

  def reset_program_user(program:, username:, password:)
    # Check if user appears in more than one program
    config = YAML.load_file(EMR_APPLICATION_CONFIG_FILE)
    dde_config = config["dde"]
    
    program_count = 0
    dde_config.each do |program_name, details|
      if details.is_a?(Hash) && details["username"] == username
        program_count += 1
      end
    end
    
    if program_count > 1
      raise "Error: Username '#{username}' is used by more than one program. Cannot reset credentials."
    end
    
    # Find or create user in database
    user = User.find_by(username: username)
    
    if user
      # User exists, update password
      user.update(password: password)
    else
      # User not found, create new user
      user = User.create(
        username: username,
        password: password
      )
    end
    
    # Update credentials in EMR-API config file
    update_emr_program_credentials(program, username, password)
    
    user_action = user.new_record? ? "created" : "updated"
    { status: :ok, message: "User '#{username}' password #{user_action} successfully for program '#{program}'. EMR-API config updated." }
  end
  
  def update_emr_program_credentials(program, username, password)
    config = YAML.load_file(EMR_APPLICATION_CONFIG_FILE)
    
    if config["dde"] && config["dde"][program].is_a?(Hash)
      config["dde"][program]["username"] = username
      config["dde"][program]["password"] = password
      
      File.open(EMR_APPLICATION_CONFIG_FILE, "w") do |f|
        f.write(config.to_yaml)
      end
    else
      raise "Program '#{program}' not found in EMR-API configuration."
    end
  end

  private

  # -----------------------------
  # Environment-specific remote
  # -----------------------------
  def remote_host
    Rails.env.production? ? "ddedashboard.hismalawi.org" : "ddetestbench.hismalawi.org"
  end

  def remote_port
    Rails.env.production? ? 9000 : 8050
  end

  def remote_base_url
    "https://#{remote_host}/v1"
  end

  # -----------------------------
  # Sync config resolution
  # -----------------------------
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

    if (sync_config[:host] || sync_config["host"]) != remote_host
      sync_config[:host] = remote_host
      updated = true
    end

    save_config(sync_config) if updated
    return { status: :ok, message: "Sync configuration updated with correct protocol/host" } if updated

    # Try authentication
    remote_success = authenticate_remote(username, password)
    local_success  = authenticate_local(username, password)

    return { status: :ok, message: "Sync authentication succeeded (proxy & master)" } if remote_success && local_success

    # Auto-reset password using default user
    new_password = SecureRandom.hex(12)
    reset_result = reset_sync_password_via_default_user(username, new_password)

    if reset_result[:status] == :ok
      sync_config[:password] = new_password
      save_config(sync_config)

      remote_success = authenticate_remote(username, new_password)
      local_success = authenticate_local(username, new_password)


      if remote_success && local_success
        { status: :ok, message: "Sync password automatically reset and authentication succeeded" }
      else
        { status: :auth_failed, message: "Password reset attempted but authentication still failed. Manual intervention needed." }
      end
    else
      { status: :auth_failed, message: "Automatic password reset failed: #{reset_result[:message]}. Please reset manually." }
    end 
  end

  # -----------------------------
  # Remote authentication
  # -----------------------------
   def authenticate_remote(username, password)
    url = "#{remote_base_url}/login?username=#{username}&password=#{password}"
    response = RestClient.post(url, {}) rescue nil
    response && response.code == 200
  end

  def authenticate_local(username, password)
    url = "http://localhost:8050/v1/login?username=#{username}&password=#{password}"
    response = RestClient.post(url, {}) rescue nil
    response && response.code == 200
  end

  # -----------------------------
  # Config helpers
  # -----------------------------
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

  # -----------------------------
  # Reset password via default user
  # -----------------------------

  def reset_sync_password_via_default_user(sync_username, new_password)
    admin_username = Rails.application.credentials.admin_username
    admin_password = Rails.application.credentials.admin_password

    return { status: :error, message: "Admin credentials missing" } unless admin_username && admin_password

    # Authenticate admin
    login_url = "#{remote_base_url}/login"
    begin
      login_resp = RestClient.post(login_url, { username: admin_username, password: admin_password })
      token = JSON.parse(login_resp.body)["access_token"]
    rescue => e
      return { status: :error, message: "Admin login failed: #{e.message}" }
    end

    # Update locally
    sync_user = User.find_by(username: sync_username)
    if sync_user.exist?
      sync_user.update(password: new_password)
    else
      User.create(username: sync_username,
                  password: new_password,
                  location_id: )
    end

    # Update remotely
    update_url = "#{remote_base_url}/update_password"
    begin
      update_resp = RestClient.post(update_url, { username: sync_username, password: new_password }, 
                                    { Authorization: token })

      return { status: :ok, message: "Password reset successfully locally and remotely" }
    rescue RestClient::ExceptionWithResponse => e
      return { status: :error, message: "Remote password reset failed: #{e.response}" }
    end
  end
  # -----------------------------
  # Sync job helpers
  # -----------------------------
  def sync_job_running?
    Sidekiq::Workers.new.any? do |process_id, thread_id, work|
      work["payload"]["class"] == SyncJob
    end
  end

  # -----------------------------
  # EMR PROGRAM CREDENTIALS
  # -----------------------------

  def get_emr_program_credentials
    begin 
      config = YAML.load_file(EMR_APPLICATION_CONFIG_FILE)
      dde_config = config["dde"]
      credentials = []

        dde_config.each do |program_name, details|
        if details.is_a?(Hash) && details.key?("username")
          credentials << {
            program: program_name,
            username: details["username"],
            password: details["password"]
          }
        end
      end 

      credentials
    rescue Errno::ENOENT
      {}
    end 
  end
end