class AddIndexesForDashboardJob < ActiveRecord::Migration[7.0]
  def change
    add_index :location_npids, %i[assigned location_id]
    add_index :location_npids, %i[location_id updated_at]
    add_index :foot_prints, %i[location_id person_uuid]
    add_index :foot_prints, %i[location_id created_at]
  end
end
