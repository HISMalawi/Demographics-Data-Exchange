# frozen_string_literal: true

# This is a class that checks for email nofication
class LastSeenLastSyncedJob < ApplicationJob
  require 'dashboard_service'
  queue_as :default

  def perform(*args)
    # Do something later

    sites = DashBoardService.site_activities

    sites.each do |site|
      # Check if last seen it greater than 3 days
      if site['days_since_last_activity'].to_i > 3
        LastSyncedMailer.last_synced_more_than_3_days(site)
      elsif site['days_since_last_seen'].to_i > 3
        LastSeenMailer.last_seen_more_than_3_days(site)
      end
    end
  end
end