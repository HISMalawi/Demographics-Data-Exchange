class PersonDetail < ApplicationRecord
  has_many :person_details_audit, foreign_key: :person_uuid, primary_key: :person_uuid
end
