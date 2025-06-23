class SyncError < ApplicationRecord
  before_create :generate_uuid

  validates :uuid, uniqueness: true

  belongs_to :location,
             foreign_key: :site_id,
             primary_key: :location_id,
             optional: true

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
