class CreateNpidsTable < ActiveRecord::Migration[7.0]
  def change
    if ENV['MASTER'] == 'true'
      create_table :npids do |t|
        t.string :npid, null: false
        t.string :version_number, null: false
        t.boolean :assigned, default: false

        t.timestamps
      end
    else
      puts 'Running default configs as proxy. This is not a master server .... skipping master npid table creation'
    end
  end
end
