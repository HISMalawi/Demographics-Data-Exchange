class AddLastSeen < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :last_seen, :datetime
  end
end
