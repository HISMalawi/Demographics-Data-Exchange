require 'rbconfig'

class ServiceManager
  def self.detect_os
    os = RbConfig::CONFIG['host_os'].downcase
    case os
    when /darwin/
      :macos
    when /linux/
      :linux
    when /mswin|mingw|cygwin/
      :windows
    else
      :unknown
    end
  end

  def self.command_for(action, service)
    case detect_os
    when :linux
      "systemctl #{action} #{service}"
    when :macos
      if %w[start stop restart].include?(action)
        "brew services #{action} #{service}"
      elsif action == "status"
        "brew services list | grep #{service}"
      end
    when :windows
      case action
      when "start"   then "sc start #{service}"
      when "stop"    then "sc stop #{service}"
      when "restart" then "sc stop #{service} && sc start #{service}"
      when "status"  then "sc query #{service}"
      end
    else
      raise "Unsupported OS"
    end
  end

  def self.run(action, service)
    allowed_actions = %w[start stop restart status]
    raise "Invalid action: #{action}" unless allowed_actions.include?(action)

    command = command_for(action, service)
    output  = `#{command} 2>&1`.strip
    success = $?.success?

    if !success || output.empty?
      raise "Service '#{service}' does not exist or could not be managed"
    end

    output
  end
end