class AddCreatorToPersonDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :person_details, :creator, :integer, null: :false
    add_column :person_details_audits, :creator, :integer, null: :false
  end
end
