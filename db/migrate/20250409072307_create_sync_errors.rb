class CreateSyncErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :sync_errors do |t|
      t.integer :site_id, null: false
      t.timestamp :incident_time, null: false
      t.string    :error, null: false
      t.boolean   :synced, null: false, default: false
      t.string    :uuid, limit: 36, null: false

      t.timestamps
    end

    add_index :sync_errors, :uuid, unique: true
  end
end
