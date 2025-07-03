class CreateSyncStatsCaches < ActiveRecord::Migration[7.0]
  if ENV['MASTER'] == 'true'
    def change
      create_table :sync_stats_caches, id: false, primary_key: :name do |t|
        t.string :name, null: false
        t.json   :value, null: false 
        t.timestamps  
      end
    end
  end
end
