module SyncService

  @batch = ActiveRecord::Base.configurations[:batch_size]['database'].to_i


  def self.person_changes_new(pull_params)
    site_id = pull_params[0]
    pull_seq = pull_params[1]
  	updates = PersonDetail.unscoped.where('location_updated_at != ? AND id > ?', site_id, pull_seq).order(:id).limit(@batch)

  	return updates
  end

  def self.person_changes_updates(pull_params)
    site_id = pull_params[0].to_i
    pull_seq = pull_params[1].to_i
    updates = PersonDetail.unscoped.joins(:person_details_audit).where('person_details.location_updated_at != ?
      AND person_details_audits.id > ?',site_id, pull_seq).order('person_details_audits.id').limit(@batch).select('person_details.*,person_details_audits.id as update_seq')

    return updates
  end

  def self.update_records_updates(data)

    push_seq = PushTracker.find_by(site_id: data[:location_updated_at].to_i, push_type: 'update')

    if push_seq.blank?
      push_seq = PushTracker.create!(site_id: data[:location_updated_at].to_i,push_seq: 0, push_type: 'update')
    end

    return {status: 200} if push_seq.push_seq > data[:update_seq].to_i # Skip data if has already been tracked

      person = PersonDetail.unscoped.find_by_person_uuid(data[:person_uuid])
      current_seq = data[:update_seq].to_i
      data.delete('id')
      data.delete('created_at')
      data.delete('updated_at')
      data.delete('update_seq')
      ActiveRecord::Base.transaction do
        if person.blank?
          PersonDetail.create!(data)
        else
            audit_record = JSON.parse(person.dup.to_json)
            person.update(data)
            audit_record.delete('id')
            audit_record.delete('created_at')
            audit_record.delete('updated_at')
            audit_record.delete('update_seq')
            PersonDetailsAudit.create!(audit_record)
        end
        LocationNpid.find_by_npid(data[:npid]).update(assigned: true)
        push_seq.update(push_seq: current_seq)
        return {status: 200, push_seq: current_seq}
      end
  end

   def self.update_records_new(data)

    push_seq = PushTracker.find_by(site_id: data[:location_updated_at].to_i, push_type: 'new')

    if push_seq.blank?
      push_seq = PushTracker.create!(site_id: data[:location_updated_at].to_i,push_seq: 0, push_type: 'new')
    end

    return {status: 200} if push_seq.push_seq > data[:id].to_i # Skip data if has already been tracked

      person = PersonDetail.unscoped.find_by_person_uuid(data[:person_uuid])
      current_seq = data[:id].to_i
      data.delete('id')
      data.delete('created_at')
      data.delete('updated_at')
      data.delete('update_seq')
      ActiveRecord::Base.transaction do
        if person.blank?
          PersonDetail.create!(data)
        else
            person.update(data)
            audit_record = JSON.parse(person.to_json)
            audit_record.delete('id')
            audit_record.delete('created_at')
            audit_record.delete('updated_at')
            audit_record.delete('update_seq')
            PersonDetailsAudit.create!(audit_record)
        end
        LocationNpid.find_by_npid(data[:npid]).update(assigned: true)
        push_seq.update(push_seq: current_seq)
        return {status: 200, push_seq: current_seq}
      end
  end

  def self.pull_npids(npid_params)
    npids = LocationNpid.where('location_id =? AND id > ? AND assigned = 0', npid_params[0],npid_params[1]).order(:id)
  end

  def self.save_footprint(footprint_record)
    footprint = FootPrint.find_by_uuid(footprint_record[:uuid])
   if footprint
         footprint = FootPrint.create(footprint_record)
   end
   return footprint
  end
end
