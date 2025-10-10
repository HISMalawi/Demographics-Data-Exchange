class NpidPoolJob < ApplicationJob
  queue_as :npid_pool

  def perform(*_args)
    # Do something later
    npid_balance = Npid.unscoped.group(:assigned).count
    DashboardStat.find_or_initialize_by(name: 'npid_balance')
                 .update(value: npid_balance)
    DashboardSocketDataJob.perform_later # this will trigger the DashboardSocketDataJob to run after this job is finished
  end
end
