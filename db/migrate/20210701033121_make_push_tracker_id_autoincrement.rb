class MakePushTrackerIdAutoincrement < ActiveRecord::Migration[5.2]
  def change
    change_column :push_trackers, :id, :int, auto_increment: true
  end
end
