class AddMigratedToMahisToLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :migrated_to_mahis, :boolean, default: false, comment: 'True if this location has been migrated to MaHIS and receives updates from centralized system'
    add_index :locations, :migrated_to_mahis
  end
end
