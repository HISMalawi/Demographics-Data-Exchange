@start_at = Time.now()

@current_district_type = PersonAttributeType.find_by_name('Current district')
@current_ta_type       = PersonAttributeType.find_by_name('Current traditional authority')
@current_village_type  = PersonAttributeType.find_by_name('Current village')

@home_district_type    = PersonAttributeType.find_by_name('Home district')
@home_ta_type          = PersonAttributeType.find_by_name('Home traditional authority')
@home_village_type     = PersonAttributeType.find_by_name('Home village')

@cell_phone_type     = PersonAttributeType.find_by_name('Cell phone number')
@work_phone_type     = PersonAttributeType.find_by_name('Work phone number')
@home_phone_type     = PersonAttributeType.find_by_name('home phone number')
@occupation_type     = PersonAttributeType.find_by_name('Occupation')
@landmark_type       = PersonAttributeType.find_by_name('Landmark')
@legacy_npid_type    = PersonAttributeType.find_by_name('Legacy identification')
@npid_type           = PersonAttributeType.find_by_name('National patient identifier')
@art_number_type     = PersonAttributeType.find_by_name('ART number')
  
def get_database_names
	databases = ActiveRecord::Base.connection.select_all <<EOF
	show databases like '%openmrs%';
EOF

	names = []
	(databases || []).each	do |n|
		names << n["Database (%openmrs%)"]
		puts names.last
	end

	return names
end

def get_version4_patient_ids(databasename)
	begin 
	patient_ids = ActiveRecord::Base.connection.select_all <<EOF
	SELECT * FROM #{databasename}.patient_identifier where length(identifier) = 6 
	AND voided = 0 and identifier_type = 3 group by patient_id ,identifier;
EOF

	rescue 
		puts "Table does not exist in #{databasename}"
	end
	
	version4_ids = []

	(patient_ids || []).each do |v4|
		version4_ids << v4['patient_id'].to_i
	end

	return version4_ids

end

def start
	names = get_database_names
	names.sort.each do |databasename|
		patient_ids = get_version4_patient_ids(databasename)
		push_records_tocouchdb(patient_ids, databasename) unless patient_ids.blank?
    #break if databasename.match(/18/i)
	end

  puts "Script done: start at: #{@start_at.strftime('%d/%b/%Y %H:%M:%S')}, ended at: #{Time.now().strftime('%d/%b/%Y %H:%M:%S')}"
end

def push_records_tocouchdb(patient_ids, database_name)
  (patient_ids || []).each_with_index do |patient_id, i|
    patient_obj = ActiveRecord::Base.connection.select_one <<EOF
    SELECT 
      t2.person_id patient_id, t2.gender, t2.birthdate, t2.birthdate_estimated,
      t2.dead, t2.death_date, t3.given_name, t3.middle_name, t3.family_name
    FROM #{database_name}.person t2
    INNER JOIN #{database_name}.person_name t3 ON t3.person_id = t2.person_id
    WHERE t2.person_id = #{patient_id} AND t3.voided = 0 AND t2.voided = 0
    GROUP BY t3.person_id ORDER BY t3.date_created DESC;
EOF

   couchdb_person = CouchdbPerson.create(given_name: patient_obj['given_name'],
    middle_name: patient_obj['middle_name'], family_name: patient_obj['family_name'],
    gender: (patient_obj['gender'].first rescue nil), 
    birthdate: (patient_obj['birthdate'].to_date rescue nil),
    birthdate_estimated: patient_obj['birthdate_estimated'],
    died: patient_obj['died'], 
    deathdate:  (patient_obj['deathdate'].to_date rescue nil),
    deathdate_estimated: patient_obj['deathdate_estimated'] )

    create_addresses(patient_id, couchdb_person, database_name)
    create_attributes(patient_id, couchdb_person, database_name)
    create_identifiers(patient_id, couchdb_person, database_name)
  
    puts "#### #{database_name}:  #{i + 1} of #{patient_ids.length}"
    #break if i == 99
   end
       
end

def create_identifiers(patient_id, couchdb_person, database_name)
  patient_identifiers = ActiveRecord::Base.connection.select_all <<EOF
  SELECT t2.name, t.identifier FROM #{database_name}.patient_identifier t
  INNER JOIN #{database_name}.patient_identifier_type t2 ON t.identifier_type = t2.patient_identifier_type_id
  WHERE t.patient_id = #{patient_id} AND t.voided = 0
  AND t2.name IN('National id','ARV Number','Old Identification Number')
  ORDER BY t.date_created DESC;
EOF

  (patient_identifiers || []).each_with_index do |patient_identifier|
    if patient_identifier['name'] == 'National id'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @npid_type.couchdb_person_attribute_type_id,
      value: patient_identifier['identifier'])
    end

    if patient_identifier['name'] == 'ARV Number'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @art_number_type.couchdb_person_attribute_type_id,
      value: patient_identifier['identifier'])
    end

    if !patient_identifier['name'] == 'ARV Number' && !patient_identifier['name'] == 'National id'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @legacy_npid_type.couchdb_person_attribute_type_id,
      value: patient_identifier['identifier'])
    end

  end

end

def create_attributes(patient_id, couchdb_person, database_name)
  patient_attributes = ActiveRecord::Base.connection.select_all <<EOF
  SELECT t2.name, t.value FROM #{database_name}.person_attribute t
  INNER JOIN #{database_name}.person_attribute_type t2 ON t.person_attribute_type_id = t2.person_attribute_type_id 
  WHERE t.person_id = #{patient_id} AND t.voided = 0
  ORDER BY t.date_created DESC;
EOF

  (patient_attributes || []).each_with_index do |patient_attribute|
    
    if patient_attribute['name'] == 'Occupation'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @occupation_type.couchdb_person_attribute_type_id,
      value: patient_attribute['value'])
    end

    if patient_attribute['name'] == 'Cell Phone Number'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @cell_phone_type.couchdb_person_attribute_type_id,
      value: patient_attribute['value'])
    end

    if patient_attribute['name'] == 'Home Phone Number'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @home_phone_type.couchdb_person_attribute_type_id,
      value: patient_attribute['value'])
    end

    if patient_attribute['name'] == 'Office Phone Number'
      CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @work_phone_type.couchdb_person_attribute_type_id,
      value: patient_attribute['value'])
    end

  end

end

def create_addresses(patient_id, couchdb_person, database_name)

  patient_addresses = ActiveRecord::Base.connection.select_one <<EOF
  SELECT 
    t.address2 home_district, t.county_district home_ta, t.neighborhood_cell home_village,
    t.state_province current_district, t.address1 current_ta, t.city_village current_village 
  FROM #{database_name}.person_address t
  WHERE t.person_id = #{patient_id} AND t.voided = 0
  GROUP BY t.person_id ORDER BY t.date_created DESC;
EOF



  unless patient_addresses['home_district'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @home_district_type.couchdb_person_attribute_type_id,
    value: patient_addresses['home_district'])
  end
   
  unless patient_addresses['home_ta'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @home_ta_type.couchdb_person_attribute_type_id,
    value: patient_addresses['home_ta'])
  end
   
  unless patient_addresses['home_village'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @home_village_type.couchdb_person_attribute_type_id,
    value: patient_addresses['home_village'])
  end
   
  unless patient_addresses['current_district'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @current_district_type.couchdb_person_attribute_type_id,
    value: patient_addresses['current_district'])
  end
   
  unless patient_addresses['current_ta'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @current_ta_type.couchdb_person_attribute_type_id,
    value: patient_addresses['current_ta'])
  end
   
  unless patient_addresses['current_village'].blank?
    CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
    person_attribute_type_id: @current_village_type.couchdb_person_attribute_type_id,
    value: patient_addresses['current_village'])
  end

end



start
