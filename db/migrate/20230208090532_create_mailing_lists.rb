class CreateMailingLists < ActiveRecord::Migration[5.2]
  def change
    if ENV['MASTER'] == 'true'
      create_table :mailing_lists do |t|
        t.string :first_name
        t.string :last_name
        t.string :email
        t.string :phone_number

        t.timestamps
      end
    else
      puts 'Only applicable on master'
    end
  end
end
