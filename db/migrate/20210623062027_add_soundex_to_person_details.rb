class AddSoundexToPersonDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :person_details, :first_name_soundex, :string, null: false
    add_column :person_details, :last_name_soundex, :string, null: false
  end

end
