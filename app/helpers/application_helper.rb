require "socket" 

module ApplicationHelper 
  def git_version
    @git_version ||= begin
      version = `git describe --tags`.chomp
      version.present? ? version : "N/A"
    rescue
      "N/A"
    end
  end

  def current_private_ip
    @current_private_ip ||=  Socket.ip_address_list.detect(&:ipv4_private?)&.ip_address
  end

end