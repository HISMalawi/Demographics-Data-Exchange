class AddForiegnKeys < ActiveRecord::Migration[5.2]
  def change
    #add_foreign_key :foot_prints,:person_details, column: :person_uuid, primary_key: :person_uuid

  end
end
