class LocationNpidJob < ApplicationJob
  queue_as :location_npid

  def perform(*args)
    # Do something later
    location_npid_balance = LocationNpid.all.group(:assigned).count
    dashboard_stat = DashboardStat.find_or_create_by(name: "location_npid_balance", value: {}) do |stat|
      stat.value = {}
    end
    dashboard_stat.update(value: location_npid_balance)
  end
  
end
