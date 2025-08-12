def start
  data = Person.where(creator: 0)

  (data || []).each_with_index do |person, i|
    couchdb_person_id   = person.couchdb_person_id
    begin
      creator     = CouchdbPerson.find(couchdb_person_id).creator
    rescue
      puts ":::::::::::::::: #{person.inspect}"
=begin
      person_attr = CouchdbPersonAttribute.find(couchdb_person_id) 
      couchdb_person_id = person_attr.person_id
      creator     = CouchdbPerson.find(person_id).creator
 
      person.update_attributes(couchdb_person_id: person_id)
=end
      raise
    end
  
    begin
    user = User.where(couchdb_user_id: creator)
    person.update_attributes(creator: user.first.user_id)
    rescue
     puts ":::::::::::::::: #{creator}"
     raise
    end
    puts "Updated >>>>>>>>> #{(i + 1)} of ... #{data.length}"
  end
end

start
