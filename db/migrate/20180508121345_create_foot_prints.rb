class CreateFootPrints < ActiveRecord::Migration[5.2]
  def change
    create_table :foot_prints, :primary_key => :foot_print_id do |t|
      t.string        :couchdb_foot_print_id,     null: false
      t.string        :npid,                      null: false
      t.string        :application,               null: false
      t.string        :couchdb_location_id,       null: false
      t.integer       :location_id,               null: false

      t.timestamps
    end
  end
end
