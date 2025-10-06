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
    when "resolve_program_users_configs"
      resolve_program_users_configs
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
    # Fetch the count of footprints per location
    footprints = FootPrint.group(:location_id).count
    # footprints will be a hash: { location_id => count }

    # Convert to array of hashes for easier handling
    footprints_array = footprints.map { |loc_id, count| { location_id: loc_id, count: count } }

    # Check if more than 2 rows exist
    if footprints_array.size > 2
      return "foot_prints belonging to more than #{footprints_array.size} sites"
    else
      return { status: :ok, message: "Footprints resolved successfully", details: footprints_array }
    end
  end

  private

  def resolve_sync_configs
    config = load_config
    sync_config = config[:dde_sync_config] || config["dde_sync_config"]
    return { status: :error, message: "Sync configuration not found" } unless sync_config

    username = sync_config[:username] || sync_config["username"]
    password = sync_config[:password] || sync_config["password"]
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

    if updated
      save_config(config)
      return { status: :ok, message: "Sync configuration updated with correct protocol/host" }
    end

    # Remote authentication
    remote_uri = URI("https://ddedashboard.hismalawi.org/v1/login?username=#{username}&password=#{password}")
    remote_response = Net::HTTP.post(remote_uri, "")
    return { status: :auth_failed, type: :remote, message: "Remote auth failed: #{remote_response.code} #{remote_response.message}" } unless remote_response.is_a?(Net::HTTPSuccess)

    # Local authentication
    port = ENV.fetch("PORT", 8050)
    local_uri = URI("http://localhost:#{port}/v1/login?username=#{username}&password=#{password}")
    local_response = Net::HTTP.post(local_uri, "")
    return { status: :auth_failed, type: :local, message: "Local auth failed: #{local_response.code} #{local_response.message}" } unless local_response.is_a?(Net::HTTPSuccess)

    { status: :ok, message: "Sync configuration is valid and authentication succeeded (proxy & master)" }
  end

  def resolve_program_users_configs
    
  end

  def get_sync_config
    config = load_config
    config[:dde_sync_config] || config["dde_sync_config"]
  end

  def load_config
    YAML.load_file(CONFIG_FILE_PATH, aliases: true)
  end

  def save_config(config)
    File.open(CONFIG_FILE_PATH, "w") { |f| f.write(config.to_yaml) }
  end

end