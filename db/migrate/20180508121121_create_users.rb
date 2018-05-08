class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users, :primary_key => :user_id do |t|
      t.string        :couchdb_user_id,   null: false
      t.string        :email,             null: false
      t.string        :password,          null: false
      t.string        :voided,            null: false, default: false, limit: 1

      t.timestamps
    end
  end
end
