# frozen_string_literal: true

# This is a class that checks for email nofication
class LastSeenLastSyncedJob < ApplicationJob
  require 'mailer_service/last_seen_last_sync_service'
  queue_as :last_seen_last_synced

  def perform(*args)
    # Send summary emails
    result = LastSeenLastSyncService.processed_data
    LastSyncedMailer.summary_of_last_synced(result[:last_activity]).deliver_later if result[:last_activity][:districts].any?
    LastSeenMailer.summary_of_last_seen(result[:last_seen]).deliver_later if result[:last_seen][:districts].any?
  end
end