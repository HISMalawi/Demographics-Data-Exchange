class CreateLocationTagMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :location_tag_maps do |t|
      t.string          :couchdb_location_tag_id,   null: false
      t.string          :couchdb_location_id,       null: false
      t.integer         :location_id,       null: false
      t.string          :location_tag_id,       null: false

      t.timestamps
    end
  end
end
