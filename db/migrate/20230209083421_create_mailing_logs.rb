class CreateMailingLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :mailing_logs do |t|
      t.integer :location_id
      t.string :notification_type

      t.timestamps
    end
    add_foreign_key :mailing_logs, :locations, column: :location_id, primary_key: :location_id
  end
end
