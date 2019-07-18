class CreateRegionDistricts < ActiveRecord::Migration[5.2]
    def change
      create_table :region_districts do |t|
        t.string      :region_id,   null: false
        t.string      :district_id,   null: false
        
        t.timestamps
      end
    end
  end