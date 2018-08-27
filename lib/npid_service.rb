
module NpidService
  
  def self.que(couchdb_person)
    NpidRegistrationQue.create(couchdb_person_id: couchdb_person.id, creator: User.current.id)
  end

  # Assign Npids to a Site/Location.
  # Takes the number of requested IDs and requesting user.
  def self.assign(number_of_ids, current_user)
    # Gets available unassigned npids from master npid table.
    available_ids = Npid.where(assigned: false).limit(number_of_ids)

    # Assign the available npids to a site /location.
    (available_ids || []).each do |n|
      ActiveRecord::Base.transaction do
        couch_location_npid = CouchdbLocationNpid.create(npid: n.npid, 
          location_id: current_user.couchdb_location_id)
        n.update_attributes(assigned: true)
        
        mysql_location = Location.find_by_couchdb_location_id(couch_location_npid.location_id)
        LocationNpid.create(
          couchdb_location_npid_id: couch_location_npid.id,
          npid: couch_location_npid.npid,
          couchdb_location_id: couch_location_npid.location_id,
          location_id: mysql_location.id
        )

      end
    end

  end

  #assigning individual npid to clients
  def self.assign_npid(couchdb_person)
    available_npid = LocationNpid.where(assigned: 0, 
      location_id: User.current.location_id).limit(100).map{|i| i.npid}.sample rescue nil

    unless available_npid.blank?
      ActiveRecord::Base.transaction do 
        location_npid = LocationNpid.find_by_npid(available_npid)
        location_npid.update_attributes(assigned: 1)
        couchdb_location_npid = CouchdbLocationNpid.find(location_npid.couchdb_location_npid_id)
        couchdb_location_npid.update_attributes(assigned: 1)

        couchdb_person.update_attributes(npid: available_npid)
        Person.find_by_couchdb_person_id(couchdb_person.id).update_attributes(npid: available_npid)
        return true
      end
    end

    return false
  end

  #   Assign npid to a patient.
  def self.assign_id_person(person, user)
    ActiveRecord::Base.transaction do
      # Get DDE User couchdb location id.
      location_id = user.couchdb_location_id

      # Get all unassigned npids for this site/location.
      npid = LocationNpid.where(["assigned = FALSE AND
        couchdb_location_id =?",location_id]).limit(1)
      
      # Assign npid to a person if unassigned npids exists.
      unless npid.blank?
        npid  = npid.first

        # Assign npid to a couchdb person.
        person.update_attributes(npid: npid.npid)

        # Assign npid to a mysql person.
        mysql_person = Person.find_by_couchdb_person_id(person.id)
        mysql_person.update_attributes(npid: person.npid)

        # Update npid in the location npids table to assigned.
        # Both in MySQL and CouchDb.
        npid.update_attributes(assigned: true)
        couchdb_location_npid = CouchdbLocationNpid.find(npid.couchdb_location_npid_id)
        couchdb_location_npid.update_attributes(assigned: true)

        ############# Void National patient identifier if it exists
        attribute_type = PersonAttributeType.find_by_name('National patient identifier')
        attributes = PersonAttribute.where("couchdb_person_id = ? 
          AND person_attribute_type_id = ?", person.id, attribute_type.id) 

        (attributes || []).each do |a|
          couchdb_person_attribute = CouchdbPersonAttribute.find(a.couchdb_person_attribute_id)
          couchdb_person_attribute.update_attributes(voided: true, void_reason: "Given new npid: #{npid}")
        end
        ###########################################################


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
