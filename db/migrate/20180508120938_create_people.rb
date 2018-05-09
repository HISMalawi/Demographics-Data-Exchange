class CreatePeople < ActiveRecord::Migration[5.2]
  def change
    create_table :people, :primary_key => :person_id do |t|
      t.string                :couchdb_person_id,     null: false
      t.string                :given_name,            null: false
      t.string                :middle_name
      t.string                :family_name,           null: false
      t.string                :gender,                null: false
      t.date                  :birthdate,             null: false
      t.boolean               :birthdate_estimated,   null: false, default: false, limit: 1
      t.boolean               :died,                  null: false, default: false, limit: 1
      t.date                  :death_date
      t.boolean               :deathdate_estimated,   default: false, limit: 1   
      t.boolean               :voided,                null: false,  default: false, limit: 1
      t.datetime              :date_voided
      t.string                :npid                  
      t.integer               :location_created_at,   null: false           
      t.integer               :creator,               null: false           

      t.timestamps
    end
    add_index :people, :npid, unique: true
    add_index :people, :couchdb_person_id, unique: true
  end
end
