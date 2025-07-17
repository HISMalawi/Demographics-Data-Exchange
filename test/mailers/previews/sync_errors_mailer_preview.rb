class SyncErrorsMailerPreview < ActionMailer::Preview
    require 'syncing_service/sync_service'

    def summary_of_sync_errors
      # Fetch recent (remaining) errors
      recent_errors = SyncService.sync_errors

      # Send recent errors via mailer only after archiving and deletion are both done
      if recent_errors.present?
        processed = process_data(recent_errors)
        districts = processed[:sync_error_districts][:districts]

        if districts.present?
            # Prepare summary data for the mailer (do not repeat in mailer)
            total_sites = districts.values.sum { |d| d[:total_sites] || 0 }
            total_sites_with_issue = districts.values.sum { |d| d[:sites_with_errors] || 0 }
            sync_error_data = {
            total_sites: total_sites,
            total_sites_with_issue: total_sites_with_issue,
            districts: districts.values
            }

            SyncErrorsMailer.summary_of_sync_errors(sync_error_data)
        else
            display_empty_mail
        end
      else
        display_empty_mail
      end
    end

    private 

    def display_empty_mail
        Mail.new(
            to: 'preview@example.com',
            from: 'no-reply@example.com',
            subject: 'Summary of Syncc Errors - No Data Available',
            body: 'There is no data available to render this preview.'
        )
    end
end