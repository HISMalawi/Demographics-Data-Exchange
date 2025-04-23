class LastSeenMailerPreview < ActionMailer::Preview
    require 'mailer_service/last_seen_last_sync_service'

    def summary_of_last_seen
        result = LastSeenLastSyncService.processed_data
      
        if result[:last_seen].present? && result[:last_seen][:districts].any?
            LastSeenMailer.summary_of_last_seen(result[:last_seen])
        else
            Mail.new(
                to: 'preview@example.com',
                from: 'no-reply@example.com',
                subject: 'Summary of Last Seen - No Data Available',
                body: 'There is no data available to render this preview.'
            )
        end
    end
end