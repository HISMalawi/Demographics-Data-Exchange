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