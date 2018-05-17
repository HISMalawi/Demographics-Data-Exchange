module FootPrintService
  
  def self.create(person, current_user)
    footprint = CouchdbFootPrint.create(
       person_id: person.couchdb_person_id,
       user_id: current_user.couchdb_user_id)
       
    return footprint
  end
  
end