class CreatePersonAttributeTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :person_attributes_types, :primary_key => :person_attr_type_id do |t|
      t.string        :couchdb_attr_type_id,                null: false
      t.string        :name,                                null: false
      t.boolean       :voided,                              null: false, default: false, limit: 1
      
      t.timestamps

    end
  end
end
