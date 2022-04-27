class DashboardSocketDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    ActionCable.server.broadcast('dashboard_channel', message: {
      total_new_registrations: PersonDetail.where('date(date_registered) = date(now())').count,
      total_new_registrations_by_site: DashboardService.new_reg_by_site,
      total_new_reg_by_site_past_30: DashboardService.new_reg_past_30,
      client_movement: DashboardService.client_movements,
      npid_state: DashboardService.npids,
      connected_state: DashboardService.connected_sites,
      site_activity: DashboardService.site_activities,
    })
  end
end