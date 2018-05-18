
module NpidService
  def self.assign(number_of_ids, current_user)

    available_ids = Npid.where(assigned: false).limit(number_of_ids)

    (available_ids || []).each do |n|
      ActiveRecord::Base.transaction do
        CouchdbLocationNpid.create(npid: n.npid, 
          location_id: current_user.couchdb_location_id)
        n.update_attributes(assigned: true)
      end
    end

  end

  def self.assign_id_person(person)
    ActiveRecord::Base.transaction do
      npid = LocationNpid.where(assigned: false).limit(1)
      if npid
        npid  = npid.first
        person.update_attributes(npid: npid.npid)
        npid.update_attributes(assigned: true)
      end
    end

    return person
  end
  
  def self.npids_assigned(params)
    
    location_doc_id = params[:location_doc_id]
    location_npids  = LocationNpid.where("couchdb_location_id = ? and
      assigned = true", location_doc_id)
      
    return {assigned_npid: location_npids.length}
  end
  
  def self.total_allocated_npids(params)
    
    location_doc_id = params[:location_doc_id]
    location_npids  = LocationNpid.where("couchdb_location_id = ?",
     location_doc_id)
      
    return {allocated_npids: location_npids.length}
    
  end

end
