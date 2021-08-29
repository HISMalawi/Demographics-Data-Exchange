class RemoveCouchdbFieldsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :couchdb_user_id
    remove_column :users, :couchdb_location_id
  end
end
