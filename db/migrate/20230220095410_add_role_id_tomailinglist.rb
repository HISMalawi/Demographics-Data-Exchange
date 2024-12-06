class AddRoleIdTomailinglist < ActiveRecord::Migration[5.2]
  def change
    if ENV['MASTER'] == 'true'
      add_column :mailing_lists, :role_id, :integer
      add_foreign_key :mailing_lists, :roles, column: :role_id, primary_key: :role_id
    else
      puts 'Only application on master skipping'
    end
  end
end
