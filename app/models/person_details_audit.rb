class PersonDetailsAudit < ApplicationRecord
  belongs_to :person_detail,->{where(voided:[true,false])},foreign_key: :person_uuid, primary_key: :person_uuid
end
