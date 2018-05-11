module PersonAttributeService
  def self.create(params, couchdb_person)

    attributes = []

    #occupation .... 
    if params[:occupation]
      attribute_type = PersonAttributeType.find_by_name('Occupation')
      attribute = CouchdbPersonAttribute.create(value: params[:occupation], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #cellphone_number .... 
    if params[:cellphone_number]
      attribute_type = PersonAttributeType.find_by_name('Cell phone number')
      attribute = CouchdbPersonAttribute.create(value: params[:cellphone_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #current_district .... 
    if params[:current_district]
      attribute_type = PersonAttributeType.find_by_name('Current district')
      attribute = CouchdbPersonAttribute.create(value: params[:current_district], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #current_ta .... 
    if params[:current_traditional_authority]
      attribute_type = PersonAttributeType.find_by_name('Current traditional authority')
      attribute = CouchdbPersonAttribute.create(value: params[:current_traditional_authority], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #current_village .... 
    if params[:current_village]
      attribute_type = PersonAttributeType.find_by_name('Current village')
      attribute = CouchdbPersonAttribute.create(value: params[:current_village], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  


    #home_district .... 
    if params[:home_district]
      attribute_type = PersonAttributeType.find_by_name('Home district')
      attribute = CouchdbPersonAttribute.create(value: params[:home_district], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #current_village .... 
    if params[:home_traditional_authority]
      attribute_type = PersonAttributeType.find_by_name('Home traditional authority')
      attribute = CouchdbPersonAttribute.create(value: params[:home_traditional_authority], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  

    #home_village .... 
    if params[:home_village]
      attribute_type = PersonAttributeType.find_by_name('Home village')
      attribute = CouchdbPersonAttribute.create(value: params[:home_village], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
    end  
=begin
    #ART number .... 
    if params[:art_number]
      attribute_type = PersonAttributeType.find_by_name('ART number').first
      attribute = CouchdbPersonAttribute.create(value: params[:art_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.id)
    end  

    #HTS .... 
    if params[:htn_number]
      attribute_type = PersonAttributeType.find_by_name('htn_number').first
      attribute = CouchdbPersonAttribute.create(value: params[:htn_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.id)
    end  
=end
  
  end
end
