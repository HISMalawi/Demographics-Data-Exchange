module PersonAttributeService
  def self.create(params, couchdb_person)

    attributes = []

    #occupation .... 
    if !params[:occupation].blank?
      attribute_type = PersonAttributeType.find_by_name('Occupation')
      ## Create attributes in couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:occupation], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:occupation], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #cellphone_number .... 
    if !params[:cellphone_number].blank?
      attribute_type = PersonAttributeType.find_by_name('Cell phone number')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:cellphone_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:cellphone_number], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #current_district .... 
    if !params[:current_district].blank?
      attribute_type = PersonAttributeType.find_by_name('Current district')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:current_district], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:current_district], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #current_ta .... 
    if !params[:current_traditional_authority].blank?
      attribute_type = PersonAttributeType.find_by_name('Current traditional authority')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:current_traditional_authority], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:current_traditional_authority], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #current_village .... 
    if !params[:current_village].blank?
      attribute_type = PersonAttributeType.find_by_name('Current village')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:current_village], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:current_village], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  


    #home_district .... 
    if !params[:home_district].blank?
      attribute_type = PersonAttributeType.find_by_name('Home district')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:home_district], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:home_district], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #current_village .... 
    if !params[:home_traditional_authority].blank?
      attribute_type = PersonAttributeType.find_by_name('Home traditional authority')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:home_traditional_authority], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:home_traditional_authority], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)
      
        attributes << [attribute_type.name, attribute.value]
    end  

    #home_village .... 
    if !params[:home_village].blank?
      attribute_type = PersonAttributeType.find_by_name('Home village')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:home_village], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:home_village], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)
      
      attributes << [attribute_type.name, attribute.value]
    end  

    #ART number .... 
    if !params[:art_number].blank?
      attribute_type = PersonAttributeType.find_by_name('ART number')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:art_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:art_number], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  

    #HTS .... 
    if !params[:htn_number].blank?
      attribute_type = PersonAttributeType.find_by_name('HTN number')
      ## Create attributes in Couchdb
      attribute = CouchdbPersonAttribute.create(value: params[:htn_number], 
        person_id: couchdb_person.id,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      ## Create attributes in MySQL.
      person = Person.find_by_couchdb_person_id(couchdb_person.id)
      PersonAttribute.create(couchdb_person_id: couchdb_person.id,
        value: params[:htn_number], 
        person_id: person.id,
        couchdb_person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id,
        person_attribute_type_id: attribute_type.id,
        couchdb_person_attribute_id: attribute.id)

      attributes << [attribute_type.name, attribute.value]
    end  
  
    return attributes
  end
  
  def self.update(params, couchdb_person)
    attributes = []

    #occupation .... 
    if !params[:occupation].blank?
      attribute_type = PersonAttributeType.find_by_name('Occupation').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:occupation], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type.couchdb_person_attribute_type_id)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:occupation])
      end
      
      attributes << couchdb_person_attribute
    end  

    #cellphone_number .... 
    if !params[:cellphone_number].blank?
      attribute_type = PersonAttributeType.find_by_name('Cell phone number').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:cellphone_number], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:cellphone_number])
      end
      
      attributes << couchdb_person_attribute
    end  

    #current_district .... 
    if !params[:current_district].blank?
      attribute_type = PersonAttributeType.find_by_name('Current district').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:current_district], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:current_district])
      end
      
      attributes << couchdb_person_attribute
    end  

    #current_ta .... 
    if !params[:current_traditional_authority].blank?
      attribute_type = PersonAttributeType.find_by_name('Current traditional authority').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:current_traditional_authority], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:current_traditional_authority])
      end
      
      attributes << couchdb_person_attribute
    end  

    #current_village .... 
    if !params[:current_village].blank?
      attribute_type = PersonAttributeType.find_by_name('Current village').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:current_village], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:current_village])
      end
      
      attributes << couchdb_person_attribute
    end  


    #home_district .... 
    if !params[:home_district].blank?
      attribute_type = PersonAttributeType.find_by_name('Home district').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:home_district], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:home_district])
      end
      
      attributes << couchdb_person_attribute
    end  

    #traditional authority .... 
    if !params[:home_traditional_authority].blank?
      attribute_type = PersonAttributeType.find_by_name('Home traditional authority').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:home_traditional_authority], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:home_traditional_authority])
      end
      
      attributes << couchdb_person_attribute
    end  

    #home_village .... 
    if !params[:home_village].blank?
      attribute_type = PersonAttributeType.find_by_name('Home village').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:home_village], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:home_village])
      end
      
      attributes << couchdb_person_attribute
    end 
    
    #HTN number .... 
    if !params[:htn_number].blank?
      attribute_type = PersonAttributeType.find_by_name('HTN NUMBER').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:htn_number], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:htn_number])
      end
      
      attributes << couchdb_person_attribute
    end 
    
    #ART number .... 
    if !params[:art_number].blank?
      attribute_type = PersonAttributeType.find_by_name('ART NUMBER').couchdb_person_attribute_type_id
      person_attr = PersonAttribute.where(["couchdb_person_id = ? AND couchdb_person_attribute_type_id =?",
        couchdb_person, attribute_type]).last
        
      if person_attr.blank?
        couchdb_person_attribute = CouchdbPersonAttribute.create(value: params[:art_number], 
        person_id: couchdb_person,
        person_attribute_type_id: attribute_type)
      else
        couchdb_person_attribute = CouchdbPersonAttribute.find(person_attr.couchdb_person_attribute_id)
        couchdb_person_attribute.update_attributes(value: params[:art_number])
      end
      
      attributes << couchdb_person_attribute
    end 
    
    return attributes
    
  end
  
end
