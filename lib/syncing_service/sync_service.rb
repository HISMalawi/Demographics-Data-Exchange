module SyncService

  def self.person_changes(site_id, pull_seq)
  	updates = PersonDetail.where('location_updated_at != ? AND id > ?', site_id, pull_seq).order(:id)

  	return updates
  end
  
end