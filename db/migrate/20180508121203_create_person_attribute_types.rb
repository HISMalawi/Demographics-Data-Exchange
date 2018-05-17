class CreatePersonAttributeTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :person_attribute_types, :primary_key => :person_attribute_type_id do |t|
      t.string        :couchdb_person_attribute_type_id,    null: false
      t.string        :name,                                null: false
      t.boolean       :voided,                              null: false, default: false, limit: 1
      t.string        :void_reason
      
      t.timestamps

    end
  end
end
