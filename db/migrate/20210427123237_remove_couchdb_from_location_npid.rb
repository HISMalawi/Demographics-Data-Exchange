class RemoveCouchdbFromLocationNpid < ActiveRecord::Migration[5.2]
  def change
    remove_column :location_npids, :couchdb_location_npid_id
    remove_column :location_npids, :couchdb_location_id
  end
end
