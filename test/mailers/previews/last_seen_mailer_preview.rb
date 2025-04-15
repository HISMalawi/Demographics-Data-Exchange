class LastSeenMailerPreview < ActionMailer::Preview
    require 'mailer_service/last_seen_last_sync_service'

    def summary_of_last_seen
        result = LastSeenLastSyncService.processed_data
        LastSeenMailer.summary_of_last_seen(result[:last_seen]).deliver_now if result[:last_seen][:districts].any?
    end
end