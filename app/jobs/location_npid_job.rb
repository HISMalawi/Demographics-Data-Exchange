class LocationNpidJob < ApplicationJob
  queue_as :location_npid

  def perform(*_args)
    # Do something later
    location_npid_balance = LocationNpid.unscoped.group(:assigned).count
    DashboardStat.find_or_initialize_by(name: 'location_npid_balance')
                 .update(value: location_npid_balance)
  end
end
