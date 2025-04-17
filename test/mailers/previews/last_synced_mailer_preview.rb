class LastSyncedMailerPreview  < ActionMailer::Preview
    require 'mailer_service/last_seen_last_sync_service'
    def summary_of_last_synced
        result = LastSeenLastSyncService.processed_data

        if result[:last_activity].present? && result[:last_activity][:districts].any?
            LastSyncedMailer.summary_of_last_synced(result[:last_activity]).deliver_now
        else
            Mail.new(
              to: 'preview@example.com',
              from: 'no-reply@example.com',
              subject: 'Summary of Last Synced - No Data Available',
              body: 'There is no data available to render this preview.'
            )
        end
    end
end