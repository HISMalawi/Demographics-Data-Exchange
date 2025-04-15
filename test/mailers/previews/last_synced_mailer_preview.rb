class LastSyncedMailerPreview  < ActionMailer::Preview
    require 'mailer_service/last_seen_last_sync_service'
    def summary_of_last_synced
        result = LastSeenLastSyncService.processed_data
        LastSyncedMailer.summary_of_last_synced(result[:last_activity])
                        .deliver_now if result[:last_activity][:districts].any?
    end
end