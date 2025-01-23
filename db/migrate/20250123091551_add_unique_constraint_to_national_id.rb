class AddUniqueConstraintToNationalId < ActiveRecord::Migration[7.0]
  def change
    add_index :person_details, :national_id, unique: true
    add_index :person_details_audits, :national_id, unique: true
  end
end
