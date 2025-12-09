class AddDefaultUserToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :default_user, :boolean, default: false, null: false

    # Set the admin user as default user
    User.reset_column_information
    User.where(username: 'admin').update_all(default_user: true)
  end

  def down
    remove_column :users, :default_user
  end
end
