module NpidRegistrationService
  def self.assign_ids
    all_jobs = NpidRegistrationQue.where(assigned: false)
    
    (all_jobs || []).each do |job|
      person = CouchdbPerson.find(job.couchdb_person_id)
      NpidService.assign_id_person(person)
      job.update_attributes(assigned: true)
      puts "Assigned ID to couchdb_person_id: #{person.id}"
    end

  end
end
