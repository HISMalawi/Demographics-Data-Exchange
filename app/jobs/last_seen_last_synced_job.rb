# frozen_string_literal: true

# This is a class that checks for email nofication
class LastSeenLastSyncedJob < ApplicationJob
  require 'dashboard_service'
  queue_as :last_seen_last_synced

  def perform(*args)
    begin 
      # Do something later
      sites = DashboardService.site_activities

      grouped_sites = {}

      sites.each do |site|
        district_id = site['district_id']
        name = site['district_name']
        
        # Initialize district hash if not already present
        grouped_sites[district_id] ||= {
          district_id: district_id,
          name: name,
          sites: {
            sites_last_seen_greater_than_3_days: [],
            sites_last_activity_greater_than_3_days: []
          }
        }

        # Add site to respective category
        if site['days_since_last_activity'].to_i > 3
          grouped_sites[district_id][:sites][:sites_last_activity_greater_than_3_days] << site
        end

        if site['days_since_last_seen'].to_i > 3
          grouped_sites[district_id][:sites][:sites_last_seen_greater_than_3_days] << site
        end
      end

      # Send emails for each district
      grouped_sites.each_value do |district_data|
        if district_data[:sites][:sites_last_activity_greater_than_3_days].any?
          LastSyncedMailer.last_synced_more_than_3_days(district_data).deliver_later
        end

        if district_data[:sites][:sites_last_seen_greater_than_3_days].any?
          LastSeenMailer.last_seen_more_than_3_days(district_data).deliver_later
        end
      end
  
    ensure
      ActiveRecord::Base.connection_pool.release_connection
    end

    

  end
end