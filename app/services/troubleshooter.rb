require "yaml"
require "net/http"
require "uri"

class Troubleshooter
  CONFIG_PATH = Rails.root.join("config", "database.yml") # adjust if your YAML is elsewhere

  def self.select_solution(error_type)
    case error_type
    when "Resolve Sync Credentials"
      resolve_sync_credentials
    when "Resolve Sync Configs"
      resolve_sync_configs
    else
      "Unknown error type"
    end
  end

  private

  def self.resolve_sync_configs
    config_file = Rails.root.join("config", "database.yml")

    # Load YAML with aliases enabled
    config = YAML.load_file(config_file, aliases: true)

    sync_config = config[:dde_sync_config] || config["dde_sync_config"]
    return "Sync configuration not found" unless sync_config

    username = sync_config[:username] || sync_config["username"]
    password = sync_config[:password] || sync_config["password"]
    return "Sync username and password not available" unless username && password

    updated = false

    # Only update the values if incorrect
    if (sync_config[:protocol] || sync_config["protocol"]).to_s.downcase != "https"
        sync_config[:protocol] = "https"
        updated = true
    end

    if (sync_config[:host] || sync_config["host"]) != "ddedashboard.hismalawi.org"
        sync_config[:host] = "ddedashboard.hismalawi.org"
        updated = true
    end

    # Save back only if values were updated
    if updated
        File.open(config_file, "w") { |f| f.write(config.to_yaml) }
        return "Sync configuration values updated to correct protocol and host"
    end

    # -- Authentication Checks ---
    remote_uri = URI("https://ddedashboard.hismalawi.org/v1/login?username=#{username}&password=#{password}")
    remote_response = Net::HTTP.post(remote_uri, "")

    unless remote_response.is_a?(Net::HTTPSuccess)
      return "Remote authentication failed: #{remote_response.code} #{remote_response.message}"
    end 

    # Local Check 
    port = ENV.fetch("PORT", 8050)

    local_uri = URI("http://localhost:#{port}/v1/login?username=#{username}&password=#{password}")
    local_response = Net::HTTP.post(local_uri, "")

    unless local_response.is_a?(Net::HTTPSuccess)
      return "Local authentication failed: #{local_response.code} #{local_response.message}"
    end


    "Sync configuration is valid and authentication succeeded (proxy & master)"
  end

  def self.resolve_sync_credentials
    # Placeholder for other checks
    "Resolving sync credentials..."
  end
end