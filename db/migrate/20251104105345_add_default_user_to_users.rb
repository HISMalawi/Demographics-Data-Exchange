class AddDefaultUserToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :default_user, :boolean, default: false, null: false
  end
end
