class AddVoidPersonDetailsFields < ActiveRecord::Migration[5.2]
  def change
    add_column :person_details, :voided, :boolean, null: false, default: 0
    add_column :person_details, :voided_by, :integer
    add_column :person_details, :date_voided, :datetime
    add_column :person_details, :void_reason, :string

    add_column :person_details_audits, :voided, :boolean, null: false, default: 0
    add_column :person_details_audits, :voided_by, :integer
    add_column :person_details_audits, :date_voided, :datetime
    add_column :person_details_audits, :void_reason, :string
  end
end
