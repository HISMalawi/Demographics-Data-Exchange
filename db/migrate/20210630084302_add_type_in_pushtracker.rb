class AddTypeInPushtracker < ActiveRecord::Migration[5.2]
  def change
    add_column :push_trackers, :push_type, :string, null: false
  end
end
