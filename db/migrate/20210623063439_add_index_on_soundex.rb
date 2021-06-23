class AddIndexOnSoundex < ActiveRecord::Migration[5.2]
  def change
    add_index :person_details, [:first_name_soundex, :last_name_soundex]
  end
end
