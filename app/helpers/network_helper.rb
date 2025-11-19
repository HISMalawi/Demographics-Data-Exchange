require "socket" 

module NetworkHelper
  # Returns the current machine’s private IPv4 address (e.g., "192.168.x.x")
  def current_private_ip
    @current_private_ip ||=  Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address
  end

end