class AddNationalIdColumnToPersonalDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :person_details, :national_id, :string
    add_column :person_details_audits, :national_id, :string
  end
end
