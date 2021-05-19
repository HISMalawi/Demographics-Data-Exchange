class ChangeAttributesToVarchar < ActiveRecord::Migration[5.2]
  def change
    change_column :person_details, :ancestry_district, :string
    change_column :person_details, :ancestry_ta, :string
    change_column :person_details, :ancestry_village, :string
    change_column :person_details, :home_district, :string
    change_column :person_details, :home_ta, :string
    change_column :person_details, :home_village, :string

    change_column :person_details_audits, :ancestry_district, :string
    change_column :person_details_audits, :ancestry_ta, :string
    change_column :person_details_audits, :ancestry_village, :string
    change_column :person_details_audits, :home_district, :string
    change_column :person_details_audits, :home_ta, :string
    change_column :person_details_audits, :home_village, :string

    change_column :person_details_audits, :gender, :string, limit: 1

  end
end
