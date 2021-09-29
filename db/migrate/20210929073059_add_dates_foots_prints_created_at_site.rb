class AddDatesFootsPrintsCreatedAtSite < ActiveRecord::Migration[5.2]
  def change
    add_column :foot_prints, :app_date_created, :datetime
    add_column :foot_prints, :app_date_updated, :datetime
  end
end
