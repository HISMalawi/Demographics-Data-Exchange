class NpidPoolJob < ApplicationJob
  queue_as :npid_pool

  def perform(*args)
    # Do something later
    npid_balance = Npid.all.group(:assigned).count
    dashboard_stat = DashboardStat.find_or_create_by(name: "npid_balance")
    dashboard_stat.update(value: npid_balance)
    DashboardSocketDataJob.perform_later # this will trigger the DashboardSocketDataJob to run after this job is finished
  end
end
