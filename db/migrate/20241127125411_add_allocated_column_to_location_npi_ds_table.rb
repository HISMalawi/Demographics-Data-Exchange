class AddAllocatedColumnToLocationNpiDsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :location_npids, :allocated, :boolean, default: false
  end
end
