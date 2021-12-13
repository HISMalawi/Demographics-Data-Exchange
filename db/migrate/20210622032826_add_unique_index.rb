class AddUniqueIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :person_details, :npid, unique: true
    add_index :person_details, :person_uuid, unique: true
  end
end
