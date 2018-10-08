class CreateDistrictSites < ActiveRecord::Migration[5.2]
    def change
      create_table :district_sites do |t|
        t.string      :district_id,   null: false
        t.string      :site_id,   null: false
        
        t.timestamps
      end
    end
  end