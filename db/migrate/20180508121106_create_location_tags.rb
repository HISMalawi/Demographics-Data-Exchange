class CreateLocationTags < ActiveRecord::Migration[5.2]
  def change
    create_table :location_tags, :primary => :location_tag_id do |t|
      t.string              :name
      t.string              :couchdb_location_tag_id, null: false

      t.timestamps
    end
  end
end
