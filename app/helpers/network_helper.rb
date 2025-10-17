require "socket" 

module NetworkHelper
  # Returns the current machine’s private IPv4 address (e.g., "192.168.x.x")
  def current_private_ip
    Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address
  end

  # Returns all locations with a matching IP
  def locations_by_current_ip
    Location.where(ip_address: current_private_ip)
  end

  # Checks for conflicts or returns the matching location (or nil if none)
  def check_ip_conflict!
    ip_address = current_private_ip
    matching_locations = locations_by_current_ip

    if matching_locations.count > 1
      raise "<strong>Conflict Detected:</strong> The IP address <strong>#{ip_address}</strong> 
      is linked to <strong>multiple locations</strong>. Please verify your network configuration or update the location records."
    elsif matching_locations.exists?
      matching_locations.first
    else
      nil
    end
  end
end