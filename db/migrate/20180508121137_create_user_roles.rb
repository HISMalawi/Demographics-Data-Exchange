class CreateUserRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :user_roles do |t|
      t.string      :couchdb_user_id, null: false
      t.string      :couchdb_role_id,  null: false
      t.integer     :role_id,         null: false
      
      t.timestamps
    end
  end
end
