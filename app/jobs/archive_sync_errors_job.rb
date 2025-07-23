class ArchiveSyncErrorsJob < ApplicationJob
  require 'syncing_service/sync_service'

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
        SyncErrorsMailer.summary_of_sync_errors(sync_error_data).deliver_later
        Rails.logger.info "[ArchiveSyncErrorsJob] Sync error summary mail sent."
      else
        Rails.logger.info "[ArchiveSyncErrorsJob] No districts found in recent errors. Mail not sent."
      end
    else
      Rails.logger.info "[ArchiveSyncErrorsJob] No recent errors to send."
    end
  end


  private 

  def process_data(sync_errors)
   
    districts = {}

    # Build a map of district_id => Set of site_ids with errors
    sites_with_errors = Hash.new { |h, k| h[k] = Set.new }
    sync_errors.each do |error|
      district_id = error.try(:district_id)
      district_name = error.try(:district_name)
      site_id = error.try(:site_id)

      next unless district_id && district_name && site_id

      districts[district_id] ||= { name: district_name, sync_errors: [] }
      districts[district_id][:sync_errors] << error
      sites_with_errors[district_id] << site_id
    end

   
    total_sites_per_district = Location.where(activated: true)
                                       .group(:district_id)
                                       .count
                                       
    districts.each do |district_id, info|
      info[:sites_with_errors] = sites_with_errors[district_id].size
      info[:total_sites] = total_sites_per_district[district_id] || 0
    end

    {
      sync_errors: sync_errors.to_a,
      sync_error_districts: { districts: districts }
    }
  end
end