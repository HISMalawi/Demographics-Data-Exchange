class PersonDetailsAudit < ApplicationRecord
  belongs_to :person_details, foreign_key: :person_uuid, primary_key: :person_uuid
end
