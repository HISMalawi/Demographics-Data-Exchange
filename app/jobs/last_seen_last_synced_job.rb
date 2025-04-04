# frozen_string_literal: true

# This is a class that checks for email nofication
class LastSeenLastSyncedJob < ApplicationJob
  require 'dashboard_service'
  queue_as :last_seen_last_synced

  def perform(*args)
    begin
      sites = DashboardService.site_activities
      last_activity_grouped = {}
      last_seen_grouped = {}

      sites.each do |site|
        district_id = site['district_id']
        name = site['district_name']

        if site['days_since_last_activity'].to_i > 3 && site['days_since_last_seen'].to_i == 0
          last_activity_grouped[district_id] ||= {
            district_id: district_id,
            name: name,
            sites_last_activity_greater_than_3_days_sites: 0,
            sites: []
          }

          last_activity_grouped[district_id][:sites_last_activity_greater_than_3_days_sites] += 1
          last_activity_grouped[district_id][:sites] << site
        end

        if site['days_since_last_seen'].to_i > 3
          last_seen_grouped[district_id] ||= {
            district_id: district_id,
            name: name,
            sites_last_seen_greater_than_3_days_sites: 0,
            sites: []
          }

          last_seen_grouped[district_id][:sites_last_seen_greater_than_3_days_sites] += 1
          last_seen_grouped[district_id][:sites] << site
        end
      end

      # Send separate summary emails
   
      LastSyncedMailer.last_synced_more_than_3_days(last_activity_grouped.values).deliver_now if last_activity_grouped.any?
      LastSeenMailer.last_seen_more_than_3_days(last_seen_grouped.values).deliver_now if last_seen_grouped.any?

    ensure
      ActiveRecord::Base.connection_pool.release_connection
    end
  end
end