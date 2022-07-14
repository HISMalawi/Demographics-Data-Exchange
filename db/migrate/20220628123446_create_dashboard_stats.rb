class CreateDashboardStats < ActiveRecord::Migration[5.2]
  def change
    create_table :dashboard_stats, id: false, :primary_key => :name do |t|
      t.string :name, null: false
      t.json :value, null: false

      t.timestamps
    end
  end
end
