# This migration comes from user_management (originally 20210613152557)
class CreateUserManagementPrivileges < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table :user_management_privileges do |t|
        t.string :name, null: false
        t.text :description, null: false

        t.timestamps
      end
    else
      puts 'Only applicable on master'
    end
  end
end
