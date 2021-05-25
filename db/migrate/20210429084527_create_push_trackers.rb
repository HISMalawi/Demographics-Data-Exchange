class CreatePushTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :push_trackers, id: false, primary_key: :site_id do |t|
      t.integer :site_id,null: false
      t.bigint :push_seq, null: false, default: 0
      t.timestamps
    end
  end
end
