class CreateDashboardStats < ActiveRecord::Migration[5.2]
  version = `mysql --version`.chomp
  if (version[(version.index(',') - 6),3].to_f >= 5.7)
    def change
      create_table :dashboard_stats, id: false, :primary_key => :name do |t|
        t.string :name, null: false
        t.json :value, null: false

        t.timestamps
      end
    end
  end
end
