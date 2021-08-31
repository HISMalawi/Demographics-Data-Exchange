class AddIndexOnNameAndGender < ActiveRecord::Migration[5.2]
  def change
    add_index :person_details, [:gender, :last_name, :first_name]
  end
end
