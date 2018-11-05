require "people_matching_service/elasticsearch_client"
require "people_matching_service/elasticsearch_person_dao"
require "people_matching_service/dde_person_transformer"

module PersonService
  
  def self.reassign_npid(params)
    couchdb_person = CouchdbPerson.find(params[:doc_id])
    return {} if couchdb_person.blank?
    person = Person.find_by_couchdb_person_id(couchdb_person.id)

    couchdb_person.update_attributes(npid: nil)
    person.update_attributes(npid: nil)

    NpidService.assign_npid(couchdb_person)   
    return self.get_person_obj(person)
  end

  def self.assign_npid(params)
    couchdb_person = CouchdbPerson.find(params[:doc_id])
    return {} if couchdb_person.blank?

    if couchdb_person.npid.blank?
      NpidService.que(couchdb_person)
      
      count = 0      
      while (couchdb_person.npid.blank? == true) do
        couchdb_person = CouchdbPerson.find(couchdb_person.id)
        if (couchdb_person.npid.blank? == false)
          break
        end
      
        if count == 5000
          break
        end
        count+= 1
      end
    end

    return self.get_person_obj(Person.find_by_couchdb_person_id(couchdb_person.id))
  end

  def self.create(params, current_user)
    location_npids = LocationNpid.where(["couchdb_location_id = ? 
      AND assigned = FALSE",current_user.couchdb_location_id])
    return {} if location_npids.blank?

    given_name              = params[:given_name]
    family_name             = params[:family_name]
    middle_name             = params[:middle_name]
    gender                  = params[:gender]
    birthdate               = params[:birthdate]
    birthdate_estimated     = params[:birthdate_estimated]
    birthdate_estimated = false if birthdate_estimated.blank?

    occupation              = params[:attributes][:occupation] rescue nil
    cellphone_number        = params[:attributes][:cellphone_number] rescue nil
    current_district        = params[:attributes][:current_district] rescue nil
    current_ta              = params[:attributes][:current_traditional_authority] rescue nil
    current_village         = params[:attributes][:current_village] rescue nil

    home_district           = params[:attributes][:home_district] rescue nil
    home_ta                 = params[:attributes][:home_traditional_authority] rescue nil
    home_village            = params[:attributes][:home_village] rescue nil

    art_number              = params[:identifiers][:art_number] rescue nil
    htn_number              = params[:identifiers][:htn_number] rescue nil

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

      #####################
      #NpidService.que(couchdb_person)
      NpidService.assign_npid(couchdb_person)
      #####################

    end
   
    if couchdb_person
      attributes = PersonAttributeService.create(params[:attributes], couchdb_person)
    end
    
    return self.after_create_get_person_obj(couchdb_person, params[:attributes])
  end

  def self.after_create_get_person_obj(person, params)
    
    person = {
      given_name:   person.given_name,
      family_name:  person.family_name,
      middle_name:  person.middle_name,
      gender: person.gender,
      birthdate:  person.birthdate,
      birthdate_estimated: person.birthdate_estimated,
      attributes: {
        occupation: params[:occupation],
        cellphone_number: params[:cellphone_number],
        current_district: params[:current_district],
        current_traditional_authority: params[:current_traditional_authority],
        current_village: params[:current_village], 
        home_district: params[:home_district],
        home_traditional_authority: params[:home_traditional_authority],
        home_village: params[:home_village]
      },
      identifiers: {
        art_number: params[:art_number],
        htn_number: params[:htn_number]
        
      },
      npid: (person.npid rescue nil),
      doc_id: person.id
    }

    es_host, es_port = Rails.application.config.elasticsearch
    es_client = ElasticsearchClient.new host: es_host, port: es_port
    es_person_dao = ElasticsearchPersonDAO.new es_client   
    es_person_dao.save DDEPersonTransformer.transform(person)

    person
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

    occupation              = params[:attributes][:occupation] rescue nil
    cellphone_number        = params[:attributes][:cellphone_number] rescue nil
    current_district        = params[:attributes][:current_district] rescue nil
    current_ta              = params[:attributes][:current_traditional_authority] rescue nil
    current_village         = params[:attributes][:current_village] rescue nil

    home_district           = params[:attributes][:home_district] rescue nil
    home_ta                 = params[:attributes][:home_traditional_authority] rescue nil
    home_village            = params[:attributes][:home_village] rescue nil

    art_number              = params[:identifiers][:art_number] rescue nil
    htn_number              = params[:identifiers][:htn_number] rescue nil
    
    
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
      couchdb_person_attr = PersonAttributeService.update(params[:attributes], doc_id) if params[:attributes]
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
     
    if person_attributes.blank?
      return {
        given_name:   person.given_name,
        family_name:  person.family_name,
        middle_name:  person.middle_name,
        gender: person.gender,
        birthdate:  person.birthdate,
        birthdate_estimated: person.birthdate_estimated,
        attributes: {
          occupation: self.get_attribute(person, "Occupation"),
          cellphone_number: self.get_attribute(person, "Cell phone number"),
          current_district: self.get_attribute(person, "Current district"),
          current_traditional_authority: self.get_attribute(person, "Current traditional authority"),
          current_village: self.get_attribute(person, "Current village"),
          home_district: self.get_attribute(person, "Home district"),
          home_traditional_authority: self.get_attribute(person, "Home traditional authority"),
          home_village: self.get_attribute(person, "Home village")
        },
          identifiers: self.get_identifiers(person),
          npid: (CouchdbPerson.find(person.couchdb_person_id).npid rescue nil),
          doc_id: person.couchdb_person_id
        }
    else
      attributes = {}
      person_attributes.map do |a|
        puts a[:person_attribute_type_name]
        attributes["#{a[:person_attribute_type_name]}"] = a[:value]
      end

      return {
        given_name:   person.given_name,
        family_name:  person.family_name,
        middle_name:  person.middle_name,
        gender: person.gender,
        birthdate:  person.birthdate,
        birthdate_estimated: person.birthdate_estimated,
        attributes: {
          occupation: attributes["Occupation"],
          cellphone_number: attributes["Cell phone number"],
          current_district: attributes["Current district"],
          current_traditional_authority: attributes["Current traditional authority"],
          current_village: attributes["Current village"],
          home_district: attributes["Home district"],
          home_traditional_authority: attributes["Home traditional authority"],
          home_village: attributes["Home village"]
        },
          identifiers: self.get_identifiers(person),
          npid: (CouchdbPerson.find(person.couchdb_person_id).npid rescue nil),
          doc_id: person.couchdb_person_id
        }
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
      identifier = self.get_attribute(person, attribute_type)
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
    
    people = Person.where(["given_name = ? 
      AND family_name = ? AND gender = ?", 
      given_name, family_name, gender]).limit(10)

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
      #people = Person.where("npid = ? OR value = ?",
        #npid, npid).joins("RIGHT JOIN person_attributes p 
      #ON p.couchdb_person_id = people.couchdb_person_id").select("people.*")
      people = []
      person = Person.where(["npid =?", npid])
      
      PersonAttribute.where(["value =?", npid]).each do |person_attribute|
        people << Person.find(person_attribute.person_id)
      end
      
      people = (person + people).uniq
      (people || []).each do |person|
        people_arr << self.get_person_obj(person)
      end

      if people_arr.length == 1
        FootPrintService.create(people.first)
      end

    end
    
    return people_arr
  end
  
  def self.search_by_doc_id(params)
    doc_id = params[:doc_id]
    person = Person.where(couchdb_person_id: doc_id)
    return [] if person.blank?
    FootPrintService.create(person.first)
    return [self.get_person_obj(person.first)]
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

  def self.total_assigned(date)
    data = Person.where("created_at BETWEEN ? AND ?", 
      date.strftime("%Y-%m-%d 00:00:00"), date.strftime("%Y-%m-%d 23:59:59"))
  
    return data.count
  end

  def self.cum_total_assigned
    data = Person.where("npid IS NOT NULL AND (given_name NOT LIKE '%test%' 
      AND family_name NOT LIKE '%test%') AND voided = 0")
  
    return data.count
  end

end

