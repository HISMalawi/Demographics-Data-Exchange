class CleanFootprints < ActiveRecord::Migration[5.2]
  def change
    change_column :person_details,:person_uuid, :binary, limit: 36
    add_column :foot_prints,:person_uuid, :binary, limit: 36
    remove_column :foot_prints, :couchdb_foot_print_id
    remove_column :foot_prints, :couchdb_person_id
    remove_column :foot_prints, :couchdb_user_id
    remove_column :foot_prints, :person_id
  end
end
