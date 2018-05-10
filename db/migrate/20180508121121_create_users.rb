class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users, :primary_key => :user_id do |t|
      t.string        :couchdb_user_id,           null: false
      t.string        :username,                  null: false
      t.string        :email
      t.string        :password_digest,           null: false
      t.string        :voided,                    null: false, default: false, limit: 1
      t.integer       :location_id,               null: false, default: 0
      t.string        :couchdb_location_id,       null: false, default: 0

      t.timestamps
    end
  end
end
