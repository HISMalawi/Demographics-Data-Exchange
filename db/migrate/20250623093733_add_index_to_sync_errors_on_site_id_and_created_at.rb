class AddIndexToSyncErrorsOnSiteIdAndCreatedAt < ActiveRecord::Migration[7.0]
  if ENV['MASTER'] == 'true'
    def change
      add_index :sync_errors, [:site_id, :created_at], name: 'index_sync_errors_on_site_id_and_created_at'
    end
  end
end
