
module NpidService

  def self.que(couchdb_person)
    NpidRegistrationQue.create(couchdb_person_id: couchdb_person.id, creator: User.current.id)
  end

  # Assign Npids to a Site/Location.
  # Takes the number of requested IDs and requesting user.
  def self.assign(number_of_ids, current_user, location = "")
    # Gets available unassigned npids from master npid table.
    available_ids = Npid.where(assigned: false).limit(number_of_ids).distinct

    # Assign the available npids to a site /location.

    location = current_user.location_id if location.blank?
    npids = 'INSERT into `location_npids` (id, location_id, npid, created_at, updated_at) VALUES '
    npid_pool_update = 'UPDATE `npids` SET assigned = true, updated_at = now() WHERE id IN ('

    available_ids.each do |npid|
      npids += "(NULL, #{location.to_i},'#{npid.npid}', now(), now()), "
      npid_pool_update += "'#{npid.id}', "
    end
      npids.chop!.chop!
      npid_pool_update.chop!.chop!
      npids += ';'
      npid_pool_update += ');'

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(npids)
        ActiveRecord::Base.connection.execute(npid_pool_update)
      end
      return available_ids
  end

  #assigning individual npid to clients
  def self.assign_npid(person)
    # available_npid = LocationNpid.where(assigned: 0,
    #   location_id: User.current.location_id).limit(1).map{|i| i.npid}.sample rescue nil

    # unless available_npid.blank?
      ActiveRecord::Base.transaction do
        if LocationNpid.where(assigned: 0,location_id: User.current.location_id).limit(100).sample.update(assigned: 1)
          return true
        else
          return 'No free npids available for location'
        end
      end
    # end
  end

  #   Assign npid to a patient.
  def self.assign_id_person(person, user)
    ActiveRecord::Base.transaction do
      # Get DDE User couchdb location id.
      location_id = user.location_id

      # Get all unassigned npids for this site/location.
      npid = LocationNpid.where(["assigned = FALSE AND
        location_id =?",location_id]).limit(100).sample

      # Assign npid to a person if unassigned npids exists.
      unless npid.blank?
        npid  = npid.first

        # Assign npid to a mysql person.
        mysql_person = PersonDetail.find_by_person_id(person.id)
        mysql_person.update_attributes(npid: person.npid)

        # Update npid in the location npids table to assigned.
        # Both in MySQL and CouchDb.
        npid.update_attributes(assigned: true)

        # ############# Void National patient identifier if it exists
        # attribute_type = PersonAttributeType.find_by_name('National patient identifier')
        # attributes = PersonAttribute.where("person_id = ?
        #   AND person_attribute_type_id = ?", person.id, attribute_type.id)

        # (attributes || []).each do |a|
        #   couchdb_person_attribute = CouchdbPersonAttribute.find(a.couchdb_person_attribute_id)
        #   couchdb_person_attribute.update_attributes(voided: true, void_reason: "Given new npid: #{npid}")
        # end
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
