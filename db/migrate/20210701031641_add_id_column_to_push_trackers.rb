class AddIdColumnToPushTrackers < ActiveRecord::Migration[5.2]
  def change
    add_column :push_trackers, :id, :int, null: false, primary_key: true
    add_index  :push_trackers, [:site_id,:push_type]
  end
end
