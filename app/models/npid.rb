class Npid < ApplicationRecord
  after_commit :update_npid

  self.primary_key = 'id'

  def update_npid
    NpidPoolJob.perform_later
    LocationNpidJob.perform_later
  end
end
