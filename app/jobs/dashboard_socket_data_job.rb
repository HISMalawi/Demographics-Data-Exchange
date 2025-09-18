class DashboardSocketDataJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Do something later
    npid_balance = DashboardStat.find_or_initialize_by(name: 'npid_balance')
    location_npid_balance = DashboardStat.find_or_initialize_by(name: 'location_npid_balance')
    dashboard_stats = DashboardStat.find_or_initialize_by(name: 'dashboard_stats')

    dash_data = {
      connected_state: DashboardService.connected_sites,
      total_new_registrations: PersonDetail.where('date_registered BETWEEN ? AND ?',
                                                  Date.today.strftime('%Y-%m-%d %H:%M:%S'), Date.today.strftime('%Y-%m-%d') + ' 23:59:59').count,
      total_new_registrations_by_site: DashboardService.new_reg_by_site,
      total_new_reg_by_site_past_30: DashboardService.new_reg_past_30,
      client_movement: DashboardService.client_movements,
      npid_state: DashboardService.npids,
      site_activity: DashboardService.site_activities,
      npid_pool: { assigned: npid_balance.value['true'], unassigned: npid_balance.value['false'] },
      allocate_npids: { assigned: location_npid_balance.value['true'],
                        unassigned: location_npid_balance.value['false'] }
    }

    dashboard_stats.update(value: dash_data)
    ActionCable.server.broadcast('dashboard_channel', { message: dash_data })
  end
end
