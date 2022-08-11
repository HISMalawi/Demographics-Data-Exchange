class Npid < ApplicationRecord
  after_commit :update_npid

  self.primary_key = 'id'

  def update_npid
    NpidPoolJob.perform_later('refresh_npid_pool')
    LocationNpidJob.perform_later('refresh_location_npids')
  end
end
