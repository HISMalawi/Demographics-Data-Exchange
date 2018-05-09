class CreatePersonAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :person_attributes, :primary_key => :person_attribute_id do |t|
      t.string                :couchdb_person_id,                 null: false
      t.integer               :person_id,                         null: false
      t.string                :couchdb_person_attribute_type_id,  null: false
      t.integer               :person_attribute_type_id,          null: false
      t.string                :couchdb_person_attribute_id,       null: false
      t.string                :value,                             null: false
      t.boolean               :voided,                            null: false,  default: false, limit: 1
      t.datetime              :date_voided
      t.integer               :voided_by

      t.timestamps
    end
  end
end
