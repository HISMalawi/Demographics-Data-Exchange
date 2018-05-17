
module MergeService

  def self.merge(primary_doc_id, secondary_doc_id)
    primary_person    = Person.find_by_couchdb_person_id(primary_doc_id)
    secondary_person  = Person.find_by_couchdb_person_id(secondary_doc_id)
    void_reason       = "Merged with: #{primary_doc_id}"
=begin
    we look for any attributes that primary_person does not have 
    but secondary_person has and we give those
    attributes to the primary_person
=end
    secondary_person_attributes = PersonAttribute.where(couchdb_person_id: secondary_doc_id)
    (secondary_person_attributes || []).each do |a|
      attribute = PersonAttribute.where("couchdb_person_id = ? AND value = ?
        AND couchdb_person_attribute_type_id = ?", primary_doc_id, 
        a.value, a.couchdb_person_attribute_type_id)  

      unless attribute.blank?
        CouchdbPersonAttribute.create(value: a.value, person_id: primary_doc_id,
          person_attribute_type_id: a.couchdb_person_attribute_type_id)
  
        couchdb_person_attribute = CouchdbPersonAttribute.find(a.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(voided: true, void_reason: void_reason)
      end

    end

    unless secondary_person.npid.blank?
      attribute = PersonAttribute.where("couchdb_person_id = ? AND value = ?", 
      primary_doc_id, secondary_person.npid)  
      
      unless attribute.blank?
        person_attribute_type = PersonAttributeType.where(name: 'National patient identifier')
        type_id = person_attribute_type.first.couchdb_person_attribute_type_id

        CouchdbPersonAttribute.create(value: secondary_person.npid, person_id: primary_doc_id,
          person_attribute_type_id: type_id)
      end
    end

    couchdb_secondary_person = CouchdbPerson.find(secondary_doc_id)
    couchdb_secondary_person.update_attributes(voided: true, void_reason: void_reason)
    
    return PersonService.get_person_obj(primary_person) 
  end

end
