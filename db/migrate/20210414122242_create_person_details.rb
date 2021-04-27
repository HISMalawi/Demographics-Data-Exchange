class CreatePersonDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :person_details do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :middle_name
      t.date :birthdate
      t.boolean :birthdate_estimated, null: false, default: 0
      t.boolean :gender, null: false
      t.integer :ancestry_district
      t.integer :ancestry_ta
      t.integer :ancestry_village
      t.integer :home_district
      t.integer :home_ta
      t.integer :home_village
      t.string  :npid, null: false, unique: true
      t.binary :person_uuid, null: false, unique: true
      t.datetime :date_registered, null: false
      t.datetime :last_edited, null: false
      t.integer :location_created_at, null: false
      t.integer :location_updated_at, null: false

      t.timestamps
    end
  end
end
