class PersonDetail < ApplicationRecord
  default_scope { where(voided: false) }

  has_many :person_details_audit, foreign_key: :person_uuid, primary_key: :person_uuid
  validates :creator,:location_created_at,:person_uuid,:date_registered,:last_edited,:first_name,:last_name, presence: true
  validates :person_uuid, :npid, uniqueness: true
  validates :national_id, uniqueness: true, allow_blank: true
end
