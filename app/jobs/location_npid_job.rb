class LocationNpidJob < ApplicationJob
  queue_as :location_npid

  def perform(*args)
    # Do something later
    location_npid_balance = LocationNpid.all.group(:assigned).count
    DashboardStat.where(:name => "location_npid_balance").update(value: location_npid_balance)
  end
end
