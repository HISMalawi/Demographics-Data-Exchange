class AssignIntNpidPrimaryKey < ActiveRecord::Migration[5.2]
  def change
    add_index :npids, :npid, unique: true
    execute "ALTER TABLE `npids` ADD PRIMARY KEY(id)"
  end
end
