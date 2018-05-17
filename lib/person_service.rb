module PersonService
  def self.create(params, current_user)

    given_name              = params[:given_name]
    family_name             = params[:family_name]
    middle_name             = params[:middle_name]
    gender                  = params[:gender]
    birthdate               = params[:birthdate]
    birthdate_estimated     = params[:birthdate_estimated]
    birthdate_estimated = false if birthdate_estimated.blank?

    occupation              = params[:attributes][:occupation]
    cellphone_number        = params[:attributes][:cellphone_number]
    current_district        = params[:attributes][:current_district]
    current_ta              = params[:attributes][:current_traditional_authority]
    current_village         = params[:attributes][:current_village]

    home_district           = params[:attributes][:home_district]
    home_ta                 = params[:attributes][:home_traditional_authority]
    home_village            = params[:attributes][:home_village]

    art_number              = params[:identifiers][:art_number]
    htn_number              = params[:identifiers][:htn_number]

    couchdb_person = nil
    person = nil

    ActiveRecord::Base.transaction do
      couchdb_person = CouchdbPerson.create(given_name: given_name, family_name: family_name,
        middle_name: middle_name, gender: gender, birthdate: birthdate,
        location_created_at: current_user.couchdb_location_id,
        birthdate_estimated: birthdate_estimated, creator: current_user.couchdb_user_id)

      person = Person.create(given_name: given_name, family_name: family_name,
        middle_name: middle_name, gender: gender, birthdate: birthdate, 
        birthdate_estimated: birthdate_estimated, location_created_at: current_user.location_id, 
        couchdb_person_id: couchdb_person.id, creator: current_user.id)

    end
   
    if couchdb_person
      couchdb_person_npid  = NpidService.assign_id_person(couchdb_person)

      attributes = PersonAttributeService.create(params[:attributes], couchdb_person)
      person_attributes = []
      
      (attributes || []).each do |attribute|
        attribute_type = CouchdbPersonAttributeType.find(attribute.person_attribute_type_id)
        person_attributes << {
          type: attribute_type.id, 
          value: attribute.value, 
          person_attribute_type_name: attribute_type.name
        }
      end

      return {person: couchdb_person, person_attributes: person_attributes}
    end
    
    return {person: couchdb_person, person_attributes: []}
  end

  def self.search_by_name_and_gender(params)
    people = Person.search_by_name_and_gender(params)
    return people
  end

  def self.search_by_npid(params)
    people = Person.search_by_npid(params)
    return people
  end
  
  def self.search_by_doc_id(params)
    people = Person.search_by_doc_id(params)
    return people
  end

  def self.search_by_attributes(params)
    people = Person.search_by_attributes(params)
    return people
  end
  
  def self.update_person(params)
    doc_id = params[:doc_id]
    couchdb_person = CouchdbPerson.find(doc_id)
    return {} if couchdb_person.blank?
    
    given_name              = params[:given_name]
    family_name             = params[:family_name]
    middle_name             = params[:middle_name]
    gender                  = params[:gender]
    birthdate               = params[:birthdate]
    birthdate_estimated     = params[:birthdate_estimated]

    occupation              = params[:attributes][:occupation]
    cellphone_number        = params[:attributes][:cellphone_number]
    current_district        = params[:attributes][:current_district]
    current_ta              = params[:attributes][:current_traditional_authority]
    current_village         = params[:attributes][:current_village]

    home_district           = params[:attributes][:home_district]
    home_ta                 = params[:attributes][:home_traditional_authority]
    home_village            = params[:attributes][:home_village]

    art_number              = params[:identifiers][:art_number]
    htn_number              = params[:identifiers][:htn_number]
    
    
    if !given_name.blank?
      couchdb_person.given_name = given_name
    end
    
    if !family_name.blank?
      couchdb_person.family_name = family_name
    end
    
    if !middle_name.blank?
      couchdb_person.middle_name = middle_name
    end
    
    if !gender.blank?
      couchdb_person.gender = gender.first.upcase
    end
    
    if !birthdate.blank?
      couchdb_person.birthdate = birthdate
    end
    
    if !birthdate_estimated.blank?
      couchdb_person.birthdate_estimated = birthdate_estimated
    end

    if couchdb_person.save
      couchdb_person_attr = PersonAttributeService.update(params[:attributes], doc_id)
    end
    
    return {person: couchdb_person, person_attributes: couchdb_person_attr}
    
  end
  
  def self.potential_duplicates(params)
    npid = params[:npid]
    potential_duplicates = Person.where(npid: npid).having('COUNT(*) > 1')
    return potential_duplicates
  end
  
  def self.merge_people(params)
    primary_npid = params[:primary_npid]
    primary_doc_id = params[:primary_doc_id]
    
    secondary_npid = params[:secondary_npid]
    secondary_doc_id = params[:secondary_doc_id]
    
    if !primary_doc_id.blank?
      primary_person = Person.where(["npid =? AND doc_id =?", primary_npid, primary_doc_id]).last
    else
      primary_person = Person.where(["npid =?", primary_npid]).last
    end
    
    if !secondary_doc_id.blank?
      secondary_person = Person.where(["npid =? AND doc_id =?", secondary_npid, secondary_doc_id]).last
    else
      secondary_person = Person.where(["npid =?", secondary_npid]).last
    end
    
    ActiveRecord::Base.transaction do
      
    end
    
  end

  def self.get_person_obj(person)
    #This is an active record object
    params = {
    given_name:   person.given_name,
    family_name:  person.family_name,
    middle_name:  person.middle_name,
    gender: person.gender,
    birthdate:  person.birthdate,
    birthdate_estimated: person.birthdate_estimated,
    attributes: {
      occupation: get_attribute(person, "Occupation"),
      cellphone_number: get_attribute(person, "Cell phone number"),
      current_district: get_attribute(person, "Current district"),
      current_traditional_authority: get_attribute(person, "Current traditional authority"),
      current_village: get_attribute(person, "Current village"),
      home_district: get_attribute(person, "Home district"),
      home_traditional_authority: get_attribute(person, "Home traditional authority"),
      home_village: get_attribute(person, "Home village")
    },
    identifiers: get_identifiers(person)
  }
 end
  
  def self.get_attribute(person, type)
    person_attribute_type_id = PersonAttributeType.find_by_name(type).id
    person_attribute = PersonAttribute.where(["person_id =? AND person_attribute_type_id =?", 
      person.person_id, person_attribute_type_id]).last
    #return person_attribute.blank? ? nil : person_attribute.value
    return person_attribute.blank? == true ? nil : person_attribute.value
    
  end
  
  def self.get_identifiers(person)
    attribute_types = ["National patient identifier", "HTN number", "ART number"]
    identifiers = []
    attribute_types.each do |attribute_type|
      identifier = get_attribute(person, attribute_type)
      unless identifier.blank?
        identifiers << {"#{attribute_type}": identifier}
      end
    end
    return identifiers
  end
  
end
