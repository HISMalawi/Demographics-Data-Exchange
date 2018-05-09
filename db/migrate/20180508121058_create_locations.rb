class CreateLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :locations, :primary_key => :location_id do |t|
      t.string          :name,                      null: false
      t.string          :couchdb_location_id,       null: false
      t.string          :description
      t.string          :latitude
      t.string          :longitude
      t.boolean         :voided,                    null: false,  default: false, limit:  1
      t.string          :couchdb_parentlocation_id
      t.integer         :parent_location
      t.string          :code
      t.integer         :creator,                   null: false

      t.timestamps
    end
  end
end
