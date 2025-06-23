class ArchiveSyncErrorsJob < ApplicationJob
  queue_as :archive_sync_errors

  def perform(*args)
    ActiveRecord::Base.transaction do
      Rails.logger.info "[ArchiveSyncErrorsJob] Archiving started..."

      cutoff = 7.days.ago
      cutoff_time = cutoff.strftime('%Y-%m-%d %H:%M:%S')

      # Move records to archive
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO sync_errors_archive
        SELECT * FROM sync_errors
        WHERE created_at < '#{cutoff_time}';
      SQL

      # Delete from main table
      ActiveRecord::Base.connection.execute <<~SQL
        DELETE FROM sync_errors
        WHERE created_at < '#{cutoff_time}';
      SQL

      Rails.logger.info "[ArchiveSyncErrorsJob] Archiving completed."
    end
  rescue => e
    Rails.logger.error "[ArchiveSyncErrorsJob] Failed: #{e.message}"
    raise
  end
end