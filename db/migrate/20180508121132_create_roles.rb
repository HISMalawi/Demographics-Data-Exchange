class CreateRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :roles, :primary_key => :role_id do |t|
      t.string        :couchdb_role_id,   null: false
      t.string        :role,              null: false

      t.timestamps
    end
  end
end
