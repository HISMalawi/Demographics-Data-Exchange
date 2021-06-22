module SyncService

  def self.person_changes(pull_params)
    site_id = pull_params[0]
    pull_seq = pull_params[1]
  	updates = PersonDetail.unscoped.where('location_updated_at != ? AND id > ?', site_id, pull_seq).order(:id).limit(100)

  	return updates
  end

  def self.update_records(data)

    push_seq = PushTracker.find_by_site_id(data[:location_updated_at].to_i)

    if push_seq.blank?
      push_seq = PushTracker.create!(site_id: data[:location_updated_at].to_i,push_seq: 0)
    end

    return {status: 200} if push_seq.push_seq > data[:id].to_i # Skip data if has already been tracked

      person = PersonDetail.find_by_person_uuid(data[:person_uuid])
      current_seq = data[:id].to_i
      data.delete('id')
      data.delete('created_at')
      data.delete('updated_at')
      ActiveRecord::Base.transaction do
        if person.blank?
          PersonDetail.create!(data)
        else
            audit_record = JSON.parse(person.to_json)
            audit_record.delete('id')
            audit_record.delete('created_at')
            audit_record.delete('updated_at')
            PersonDetailsAudit.create!(audit_record)
            person.destroy!
            PersonDetail.create!(data)
        end
        push_seq.update(push_seq: current_seq)
        return {status: 200, push_seq: current_seq}
      end
  end

  def self.pull_npids(npid_params)
    npids = LocationNpid.where('location_id =? AND id > ? AND assigned = 0', npid_params[0],npid_params[1]).order(:id)
  end
end
