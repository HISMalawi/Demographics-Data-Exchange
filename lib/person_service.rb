module PersonService
  def self.create(params, current_user)

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
      person_attributes = []

      PersonAttributeService.create(params[:attributes], couchdb_person)
      
      (PersonAttribute.where(person_id: person.id) || []).each do |a|
        person_attribute_type = PersonAttributeType.find(a.person_attribute_type_id)
        person_attributes << {
          type: person_attribute_type.id, value: a.value, 
          person_attribute_type_name: person_attribute_type.name
        }
      end

      return {person: couchdb_person, person_attributes: person_attributes}
    end
    
    return {person: couchdb_person, person_attributes: []}
  end



end
