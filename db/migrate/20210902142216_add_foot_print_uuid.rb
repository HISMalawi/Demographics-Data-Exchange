class AddFootPrintUuid < ActiveRecord::Migration[5.2]
  def change
    add_column :foot_prints, :uuid, :binary, limit: 36, null: false, unique: true
  end
end
