# This migration comes from user_management (originally 20210614023528)
class AddForeignKeyContraints < ActiveRecord::Migration[7.0]
  if ENV['MASTER'] == 'true'
    def change
      add_foreign_key :user_management_user_privileges, :user_management_users, column: :user_id, primary_key: :user_id
    end
  else
    puts 'Only applicable on master'
  end
end
