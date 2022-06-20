class AddDdeActivatedSite < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :activated, :boolean, null: false, default: false 
    add_index :locations, :activated
  end
end
