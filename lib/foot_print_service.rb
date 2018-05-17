module FootPrintService
  
  def self.create(person)
    footprint = CouchdbFootPrint.create(
       person_id: person.couchdb_person_id,
       user_id: User.current.couchdb_user_id)
       
    return footprint
  end
  
end
