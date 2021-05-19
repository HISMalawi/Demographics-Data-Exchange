class AssignIntNpidPrimaryKey < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE `npids` DROP PRIMARY KEY"
    execute "ALTER TABLE `npids` ADD PRIMARY KEY(id)"
  end
end
