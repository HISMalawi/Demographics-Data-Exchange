class AddIndexesForDashboardPerformance < ActiveRecord::Migration[5.2]
  def change
    add_index :person_details, [:voided, :date_registered]
    add_index :locations, [:ip_address, :name]
    add_index :location_npids, :location_id
    add_index :foot_prints, :location_id
  end
end
