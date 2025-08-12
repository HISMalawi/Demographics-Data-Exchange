class Api::V1::TroubleshootingController <  ActionController::Base
  layout "application" 

  def index
  end

  def sync_status
  end

  def logs
  end

  def network_check
  end

  def troubleshoot
    debugger
    puts "Seomthing inside so strong"
  end
end