class DashboardSocketDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    if File.exists?("#{Rails.root}/log/npid_balance.json")
      npid_balance = JSON.parse(File.read("#{Rails.root}/log/npid_balance.json"))
    else
      npid_balance = Npid.all.group(:assigned).count
      File.write("#{Rails.root}/log/npid_balance.json", npid_balance.to_json)
    end

    ActionCable.server.broadcast('dashboard_channel', message: {
      connected_state: DashboardService.connected_sites,
      total_new_registrations: PersonDetail.where('date_registered BETWEEN ? AND ?',Date.today.strftime('%Y-%m-%d %H:%M:%S'),Date.today.strftime('%Y-%m-%d') + ' 23:59:59').count,
      total_new_registrations_by_site: DashboardService.new_reg_by_site,
      total_new_reg_by_site_past_30: DashboardService.new_reg_past_30,
      client_movement: DashboardService.client_movements,
      npid_state: DashboardService.npids,
      site_activity: DashboardService.site_activities,
      npid_pool: {assigned: npid_balance['true'], unassigned: npid_balance['false']}
    })
  end
end
