class AssignIntNpidPrimaryKey < ActiveRecord::Migration[5.2]
  def change
    # add_index :npids, :npid, unique: true unless index_exists(:npids,:npid)
    # execute "ALTER TABLE `npids` DROP PRIMARY KEY"
    # execute "ALTER TABLE `npids` ADD PRIMARY KEY(id)"
  end
end
