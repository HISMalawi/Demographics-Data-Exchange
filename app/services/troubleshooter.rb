require "yaml"
require "net/http"
require "uri"

class Troubleshooter
  CONFIG_PATH = Rails.root.join("config", "database.yml")

  def self.select_solution(error_type)
    case error_type
    when "Resolve Sync Credentials"
      resolve_sync_credentials
    when "Resolve Sync Configs"
      resolve_sync_configs
    else
      { status: :unknown, message: "Unknown error type" }
    end
  end

  private

  def self.resolve_sync_configs
    config_file = Rails.root.join("config", "database.yml")
    config = YAML.load_file(config_file, aliases: true)
    sync_config = config[:dde_sync_config] || config["dde_sync_config"]
    return { status: :error, message: "Sync configuration not found" } unless sync_config

    username = sync_config[:username] || sync_config["username"]
    password = sync_config[:password] || sync_config["password"]
    return { status: :auth_failed, message: "Sync username and password not available" } unless username && password

    updated = false

    # Update protocol/host if incorrect
    if (sync_config[:protocol] || sync_config["protocol"]).to_s.downcase != "https"
      sync_config[:protocol] = "https"
      updated = true
    end

    if (sync_config[:host] || sync_config["host"]) != "ddedashboard.hismalawi.org"
      sync_config[:host] = "ddedashboard.hismalawi.org"
      updated = true
    end

    if updated
      File.open(config_file, "w") { |f| f.write(config.to_yaml) }
      return { status: :ok, message: "Sync configuration values updated to correct protocol and host" }
    end

    # Remote authentication check
    remote_uri = URI("https://ddedashboard.hismalawi.org/v1/login?username=#{username}&password=#{password}")
    remote_response = Net::HTTP.post(remote_uri, "")

    return { status: :auth_failed, type: :remote, message: "Remote authentication failed: #{remote_response.code} #{remote_response.message}" } unless remote_response.is_a?(Net::HTTPSuccess)

    # Local authentication check
    port = ENV.fetch("PORT", 8050)
    local_uri = URI("http://localhost:#{port}/v1/login?username=#{username}&password=#{password}")
    local_response = Net::HTTP.post(local_uri, "")

    return { status: :auth_failed, type: :local, message: "Local authentication failed: #{local_response.code} #{local_response.message}" } unless local_response.is_a?(Net::HTTPSuccess)

    { status: :ok, message: "Sync configuration is valid and authentication succeeded (proxy & master)" }
  end

  def self.resolve_sync_credentials
    { status: :ok, message: "Resolving sync credentials..." }
  end
end