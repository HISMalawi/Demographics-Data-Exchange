class AddAdditionalFieldsInFootPrints < ActiveRecord::Migration[5.2]
  def change
    add_column :foot_prints, :program_id, :integer, null: false
    add_column :foot_prints, :location_id, :integer, null: false
    add_column :foot_prints, :synced, :boolean, default: false
  end
end
