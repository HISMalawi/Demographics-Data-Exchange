class CreateSyncErrorsArchive < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS sync_errors_archive LIKE sync_errors;
    SQL
  end

  def down
    drop_table :sync_errors_archive, if_exists: true
  end
end