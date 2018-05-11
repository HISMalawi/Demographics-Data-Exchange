class CreateLocationNpids < ActiveRecord::Migration[5.2]
  def change
    create_table :location_npids do |t|
      t.string    :couchdb_location_id  
      t.integer   :location_id
      t.string    :npid
      t.boolean 	:assigned,		            null: false, default: false, limit: 1   
      t.timestamps
    end
    add_index :location_npids, :npid, unique: true
  end
end
