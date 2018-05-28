class CreateNpidRegistrationQues < ActiveRecord::Migration[5.2]
  def change
    create_table :npid_registration_ques do |t|
      t.string          :couchdb_person_id, null: false
      t.boolean         :assigned,          null: false, default: false, limit: 1
      t.integer         :creator,           null: false           


      t.timestamps
    end
  end
end
