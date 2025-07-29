# This migration comes from user_management (originally 20210613152630)
class CreateUserManagementUsers < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table  :user_management_users, id: false do |t|
        t.integer   :user_id, null: false, primary_key: true
        t.string    :username, null: false
        t.string    :email
        t.string    :password
        t.string    :password_digest
        t.integer   :person_id, null: false

        t.timestamps
      end
    else
      puts 'Only applicable on master'
    end
  end
end
