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
    
      #####################
      NpidService.que(couchdb_person)
      #####################

      person = Person.create(given_name: given_name, family_name: family_name,
        middle_name: middle_name, gender: gender, birthdate: birthdate, 
        birthdate_estimated: birthdate_estimated, location_created_at: current_user.location_id, 
        couchdb_person_id: couchdb_person.id, creator: current_user.id)

    end
   
    if couchdb_person

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

      unless htn_number.blank?
        PersonAttributeService.create({htn_number: htn_number}, couchdb_person)
        type = PersonAttributeType.find_by_name('HTN number')
        person_attributes << {
          type: type.couchdb_person_attribute_type_id, 
          value: htn_number, 
          person_attribute_type_name: type.name
        }
      end
  
      unless art_number.blank?
        PersonAttributeService.create({art_number: art_number}, couchdb_person)
        type = PersonAttributeType.find_by_name('ART number')
        person_attributes << {
          type: type.couchdb_person_attribute_type_id, 
          value: art_number, 
          person_attribute_type_name: type.name
        }
      end
  
      #return {person: couchdb_person, person_attributes: person_attributes}
      #return {person: self.get_person_obj(person), person_attributes: person_attributes}
    end

    count = 0

    while (couchdb_person.npid.blank? == true) do
      couchdb_person = CouchdbPerson.find(couchdb_person.id)
      npids_assigned = (couchdb_person.npid.blank? == true ? false : true)
      if (couchdb_person.npid.blank? == false)
        return self.get_person_obj(person)
        break
      end
    
      if count == 5000
        puts "################## 1  #{person.npid.blank?}"
        break
      end
      count+= 1
    end

    return self.get_person_obj(person, person_attributes)
    #return self.get_person_obj(person)
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

  def self.get_person_obj(person, person_attributes = [])
    #This is an active record object
    person_attributes = []

    if person_attributes.blank?
      return {
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
          identifiers: get_identifiers(person),
          npid: (CouchdbPerson.find(person.couchdb_person_id).npid rescue nil),
          doc_id: person.couchdb_person_id
        }
    else
=begin
      return {
        given_name:   person.given_name,
        family_name:  person.family_name,
        middle_name:  person.middle_name,
        gender: person.gender,
        birthdate:  person.birthdate,
        birthdate_estimated: person.birthdate_estimated,
        attributes: person_attributes.map{|a| ["#{CouchdbPersonAttributeType.find(a.person_attribute_type_id).name}", a.value] },
          identifiers: get_identifiers(person),
          npid: (CouchdbPerson.find(person.couchdb_person_id).npid rescue nil),
          doc_id: person.couchdb_person_id
        }
=end
    end
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

  def self.search_by_name_and_gender(params)
    given_name  = params[:given_name]
    family_name = params[:family_name]
    gender      = params[:gender]
    
    people = Person.where(["given_name = ? AND family_name = ? AND gender = ?", 
      given_name, family_name, gender])

    people_arr = []
    
    (people || []).each do |person|
      people_arr << self.get_person_obj(person)
    end

    return people_arr
  end
  
  def self.search_by_npid(params)
    npid = params[:npid]
    doc_id = params[:doc_id]
    
    unless doc_id.blank?
      person = Person.find_by_couchdb_person_id(doc_id)
      unless person.blank?
        person_obj = self.get_person_obj(person)
        FootPrintService.create(person)

        return [person_obj]
      end
    end

    people_arr = []

    unless npid.blank?
      people = Person.where("npid = ? OR value = ?",
        npid, npid).joins("RIGHT JOIN person_attributes p 
      ON p.couchdb_person_id = people.couchdb_person_id").select("people.*")

      (people || []).each do |person|
        people_arr << self.get_person_obj(person)
      end
    end
    
    return people_arr
  end
  
  def self.search_by_doc_id(params)
    doc_id = params[:doc_id]
    person = Person.where(couchdb_person_id: doc_id)
    return [] if person.blank?
    return self.get_person_obj(person.first)
  end
  
  def self.search_by_attributes(params)
    values = params[:values]
    
    if !(values.is_a?(Array))
      values = []
    end
    
    if values.blank?
      values = []
    end
    
    people = Person.where(["value IN (?)", values]).joins("INNER JOIN person_attributes p
    ON p.couchdb_person_id = people.couchdb_person_id").select("people.*")

    people_arr = []

    (people || []).each do |person|
      people_arr << self.get_person_obj(person)
    end

    return people_arr
  end
  
end

