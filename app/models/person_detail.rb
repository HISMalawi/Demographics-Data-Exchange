class PersonDetail < ApplicationRecord
  default_scope { where(voided: false) }

  has_many :person_details_audit, foreign_key: :person_uuid, primary_key: :person_uuid
  validates :creator,:location_created_at,:person_uuid,:date_registered,:last_edited,:first_name,:last_name, presence: true
  validates :person_uuid, :npid, uniqueness: true
  validates :national_id, uniqueness: true, allow_blank: true
  validate :valid_national_id, if: -> { national_id.present? }

  private

  # Custom validation for Malawi National ID
  def valid_national_id
    unless national_id.match?(/\A(?!.*S)[A-Z0-9]{8}\z/)
      errors.add(:national_id, "must be exactly 8 alphanumeric characters and cannot contain the letter 'S'")
    end
  end
end
 