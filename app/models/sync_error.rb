class SyncError < ApplicationRecord
  before_create :generate_uuid

  validates :uuid, uniqueness: true

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
