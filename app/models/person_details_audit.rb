class PersonDetailsAudit < ApplicationRecord
  belongs_to :person_detail, foreign_key: :person_uuid, primary_key: :person_uuid
end
