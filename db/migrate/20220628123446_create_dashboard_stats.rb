class CreateDashboardStats < ActiveRecord::Migration[5.2]
  # version = `mysql --version`.chomp
  def change
    result = ActiveRecord::Base.connection.select_one "SHOW VARIABLES WHERE variable_name = 'version'"
    table_exist = ActiveRecord::Base.connection.data_source_exists?('dashboard_stats')
    return if result['Value'].include?('5.6') || table_exist

    create_table :dashboard_stats, id: false, primary_key: :name do |t|
      t.string :name, null: false
      t.json :value, null: false

      t.timestamps
    end

  end
end
