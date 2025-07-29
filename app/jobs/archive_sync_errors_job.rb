class ArchiveSyncErrorsJob < ApplicationJob
  require 'syncing_service/sync_service'
  require 'syncing_service/sync_error_processor'

  queue_as :archive_sync_errors

  def perform(*args)
    cutoff = 7.days.ago
    cutoff_time = cutoff.strftime('%Y-%m-%d %H:%M:%S')

    # Archive and delete old sync errors in a transaction
    ActiveRecord::Base.transaction do
      Rails.logger.info "[ArchiveSyncErrorsJob] Archiving started..."
      begin
        # Move old records to archive table
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO sync_errors_archive SELECT * FROM sync_errors WHERE created_at < '#{cutoff_time}';
        SQL
        # Delete from main table
        ActiveRecord::Base.connection.execute <<~SQL
          DELETE FROM sync_errors WHERE created_at < '#{cutoff_time}';
        SQL
        Rails.logger.info "[ArchiveSyncErrorsJob] Archiving completed."
      rescue => e
        Rails.logger.error "[ArchiveSyncErrorsJob] Archiving failed: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    # Fetch recent (remaining) errors
    recent_errors = SyncService.sync_errors

    # Send recent errors via mailer only after archiving and deletion are both done
    if recent_errors.present?
      processed = SyncingService::SyncErrorProcessor.process(recent_errors)
      districts = processed[:sync_error_districts][:districts]

      if districts.present?
        sync_error_data = SyncingService::SyncErrorProcessor.build_sync_summary_data(districts)

        SyncErrorsMailer.summary_of_sync_errors(sync_error_data).deliver_later
        Rails.logger.info "[ArchiveSyncErrorsJob] Sync error summary mail sent."
      else
        Rails.logger.info "[ArchiveSyncErrorsJob] No districts found in recent errors. Mail not sent."
      end
    else
      Rails.logger.info "[ArchiveSyncErrorsJob] No recent errors to send."
    end
  end

end