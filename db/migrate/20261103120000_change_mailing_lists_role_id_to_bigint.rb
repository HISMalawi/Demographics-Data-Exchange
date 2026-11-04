class ChangeMailingListsRoleIdToBigint < ActiveRecord::Migration[7.0]
  def up
    return unless ENV['MASTER'] == 'true'

    remove_foreign_key :mailing_lists, column: :role_id if foreign_key_exists?(:mailing_lists, column: :role_id)
    change_column :mailing_lists, :role_id, :bigint
    add_foreign_key :mailing_lists, :roles, column: :role_id, primary_key: :role_id
  end

  def down
    return unless ENV['MASTER'] == 'true'

    remove_foreign_key :mailing_lists, column: :role_id if foreign_key_exists?(:mailing_lists, column: :role_id)
    change_column :mailing_lists, :role_id, :integer
    add_foreign_key :mailing_lists, :roles, column: :role_id, primary_key: :role_id
  end
end
