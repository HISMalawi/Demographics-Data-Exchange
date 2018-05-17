class CreateFootPrints < ActiveRecord::Migration[5.2]
  def change
    create_table :foot_prints, :primary_key => :foot_print_id do |t|
      t.string        :couchdb_foot_print_id,     null: false
      t.integer       :person_id,                 null: false
      t.string        :couchdb_person_id,         null: false
      t.integer       :user_id,                   null: false
      t.string        :couchdb_user_id,           null: false

      t.timestamps
    end
  end
end
