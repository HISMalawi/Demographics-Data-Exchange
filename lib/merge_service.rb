
module MergeService

  def self.merge(primary_doc_id, secondary_doc_id)
    primary_person    = Person.find_by_couchdb_person_id(primary_doc_id)
    return [] if primary_person.blank?
    secondary_person  = Person.find_by_couchdb_person_id(secondary_doc_id)
    return [] if secondary_person.blank?
    void_reason       = "Merged with: #{primary_doc_id}"
=begin
    we look for any attributes that primary_person does not have 
    but secondary_person has and we give those
    attributes to the primary_person
=end
   
    primary_person_attributes    = PersonAttribute.where(couchdb_person_id: primary_doc_id)
    secondary_person_attributes  = PersonAttribute.where(couchdb_person_id: secondary_doc_id)
    npids = []
    npid_attribute_type = PersonAttributeType.find_by_name('National patient identifier')

    (secondary_person_attributes || []).each do |secondary_attribute|
      available = PersonAttribute.where("couchdb_person_id = ? 
        AND person_attribute_type_id = ?", primary_doc_id, secondary_attribute.person_attribute_type_id)
      
      npids << secondary_attribute.value if secondary_attribute.person_attribute_type_id == npid_attribute_type

      if available.blank?
        couchdb_attribute = CouchdbPersonAttribute.find(secondary_attribute.couchdb_person_attribute_id)
        couchdb_attribute.update_attributes(voided: 1, void_reason: void_reason)
        secondary_attribute.update_attributes(voided: 1, void_reason: void_reason)
 
        new_attribute = CouchdbPersonAttribute.create(value: couchdb_attribute.value, 
          person_attribute_type_id: couchdb_attribute.person_attribute_type_id, person_id: primary_doc_id)
        
        PersonAttribute.create(value: couchdb_attribute.value, couchdb_person_id: primary_doc_id,
          person_id: primary_person.id, person_attribute_type_id: secondary_attribute.person_attribute_type_id,
          couchdb_person_attribute_id: new_attribute.id) 
      else
        couchdb_attribute = CouchdbPersonAttribute.find(secondary_attribute.couchdb_person_attribute_id)
        couchdb_attribute.update_attributes(voided: 1, void_reason: void_reason)
        secondary_attribute.update_attributes(voided: 1, void_reason: void_reason)
      end

    end
  
    npids << primary_person.npid unless primary_person.npid.blank?
    npids = npids.uniq rescue []
    
    CouchdbPerson.find(secondary_doc_id).update_attributes(void_reason: void_reason: voided: 1)
    secondary_person.update_attributes(void_reason: void_reason, voided: 1)


    if primary_person.npid.blank? && !npids.blank?
      begin
        if npids[0].length == 6
          primary_person.update_attributes(npid: npids[0])
        end
      rescue
        ### to be completed 
      end
    end
    
    return PersonService.get_person_obj(primary_person) 
  end

end
