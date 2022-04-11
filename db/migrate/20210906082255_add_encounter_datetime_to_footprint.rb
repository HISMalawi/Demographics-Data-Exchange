class AddEncounterDatetimeToFootprint < ActiveRecord::Migration[5.2]
  def change
    add_column :foot_prints, :encounter_datetime, :datetime
  end
end
