class CreateMailerLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :mailer_locations do |t|
      t.integer :location_id
      t.bigint :mailer_id

      t.timestamps
    end
    add_foreign_key :mailer_locations, :locations, column: :location_id, primary_key: :location_id
    add_foreign_key :mailer_locations, :mailing_lists, column: :mailer_id, primary_key: :id
  end
end
