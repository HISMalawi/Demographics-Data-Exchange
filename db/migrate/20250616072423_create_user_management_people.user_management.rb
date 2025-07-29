# This migration comes from user_management (originally 20210613151258)
class CreateUserManagementPeople < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table :user_management_people, id: false, if_not_exists: true do |t|
        t.integer :person_id, null: false, primary_key: true
        t.string :national_id
        t.string :first_name, null: false
        t.string :surname, null: false
        t.string :other_name
        t.date :birthdate
        t.string :sex, limit: 1
        t.integer :phone_number

        t.timestamps
      end
    else 
      puts 'Only applicable on master'
    end 
  end
end
