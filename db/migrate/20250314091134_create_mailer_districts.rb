class CreateMailerDistricts < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table :mailer_districts do |t|
        t.bigint :district_id, null: false
        t.bigint  :mailer_id, null: false
        t.boolean :voided, default: false
        t.timestamps
      end

      add_column  :mailing_logs, :district_id, :bigint
      #add_foreign_key :mailer_districts, :districts, column: :district_id, primary_key: :district_id
      add_foreign_key :mailer_districts, :mailing_lists, column: :mailer_id, primary_key: :id
      #add_foreign_key :mailing_logs, :districts, column: :district_id, primary_key: :district_id
    else
      puts 'Only applicable on master'
    end
  end
end
