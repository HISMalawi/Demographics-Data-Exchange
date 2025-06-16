# This migration comes from user_management (originally 20210613152744)
class CreateUserManagementUserPrivileges < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table :user_management_user_privileges, id: false do |t|
        t.integer :user_privilege_id, null: false, primary_key: true
        t.integer :user_id, null: false
        t.integer :privilege_id, null: false
        t.boolean :active, null: false

        t.timestamps
      end
    else 
      puts 'Only applicable on master'
    end
  end
end
