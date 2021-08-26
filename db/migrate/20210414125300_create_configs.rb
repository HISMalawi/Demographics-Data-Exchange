class CreateConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :configs do |t|
      t.string :config, null: false
      t.string :config_value, null: false
      t.string :description, null: false
      t.binary :uuid, null: false

      t.timestamps
    end
  end
end
