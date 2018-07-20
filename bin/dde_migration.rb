@start_at = Time.now()
@sql_patient_id = 0 #2_026_467 #0
@sql_patient_attribute_id = 0 #16_858_825 #0

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

@location_created_at = Location.find_by_name('Baobab Health Trust')
@user = User.find_by_username('admin')

@first_loop = true
@first_loop2 = true
  
File.open("#{Rails.root}/log/people.sql", "a+"){|f| 
  string =<<EOF
INSERT INTO people (person_id, couchdb_person_id, given_name,middle_name,family_name,gender,birthdate,birthdate_estimated,died,deathdate,deathdate_estimated,location_created_at, creator,created_at,updated_at) VALUES 
EOF

  f << string
}


File.open("#{Rails.root}/log/person_attributes.sql", "a+"){|f| 
  string =<<EOF
INSERT INTO person_attributes (person_attribute_id, couchdb_person_id, person_id, couchdb_person_attribute_type_id, person_attribute_type_id, couchdb_person_attribute_id, value, created_at, updated_at) VALUES 
EOF

  f << string
}



def get_database_names
	databases = ActiveRecord::Base.connection.select_all <<EOF
	show databases like '%openmrs%';
EOF

	names = []
	(databases || []).each_with_index	do |n, i|
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
  # names = ["openmrs_QECH_ART", "openmrs_RU", "openmrs_SAL", "openmrs_SLK", 
  #   "openmrs_SL_ART", "openmrs_SMH", "openmrs_STH", "openmrs_STJM", "openmrs_SUC_ART", 
  #   "openmrs_TBHC", "openmrs_TDHC", "openmrs_THY", "openmrs_TKHC_ART", 
  #   "openmrs_ZCH_ANC_DDE_demographics", "openmrs_ZCH_ARV_ART", "openmrs_ZINGW_ART", 
  #   "openmrs_mbangombe", "openmrs_namasalima", "openmrs_ngoni", "openmrs_ukwe"]
	names.sort.each_with_index do |databasename, i|
		patient_ids = get_version4_patient_ids(databasename)
		push_records_tocouchdb(patient_ids, databasename) unless patient_ids.blank?
    #break if databasename.match(/18/i)
	end

  puts "Script done: start at: #{@start_at.strftime('%d/%b/%Y %H:%M:%S')}, ended at: #{Time.now().strftime('%d/%b/%Y %H:%M:%S')}"
end

def push_records_tocouchdb(patient_ids, database_name)
  (patient_ids || []).each_with_index do |patient_id, i|
    # next if i < 229_810 && database_name == "openmrs_QECH_ART"
    #create a patient_id that will be used in the SQL file
    @sql_patient_id += 1
    
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
    deathdate_estimated: patient_obj['deathdate_estimated'],
    location_created_at:  @location_created_at.couchdb_location_id,
    creator:  @user.couchdb_user_id )

    push_to_people_sql_file(couchdb_person)


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
    begin  
      if patient_identifier['name'] == 'National id'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @npid_type.couchdb_person_attribute_type_id,
        value: patient_identifier['identifier'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @npid_type.id)
      end
    rescue
      puts "Error: ........ #{patient_identifier.inspect}"
    end

    begin
      if patient_identifier['name'] == 'ARV Number'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @art_number_type.couchdb_person_attribute_type_id,
        value: patient_identifier['identifier'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @art_number_type.id)
      end
    rescue
      puts "Error: ........ #{patient_identifier.inspect}"
    end

    begin
      if !patient_identifier['name'] == 'ARV Number' && !patient_identifier['name'] == 'National id'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @legacy_npid_type.couchdb_person_attribute_type_id,
        value: patient_identifier['identifier'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @legacy_npid_type.id)
      end
    rescue
      puts "Error: ........ #{patient_identifier.inspect}"
    end

  end

end

def create_attributes(patient_id, couchdb_person, database_name)
  patient_attributes = ActiveRecord::Base.connection.select_all <<EOF
  SELECT t2.name, t.value FROM #{database_name}.person_attribute t
  INNER JOIN #{database_name}.person_attribute_type t2 ON t.person_attribute_type_id = t2.person_attribute_type_id 
  WHERE t.person_id = #{patient_id} AND t.voided = 0 AND LENGTH(t.value) > 0
  ORDER BY t.date_created DESC;
EOF

  (patient_attributes || []).each_with_index do |patient_attribute|
    
    begin
      if patient_attribute['name'] == 'Occupation'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @occupation_type.couchdb_person_attribute_type_id,
        value: patient_attribute['value'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @occupation_type.id)
      end
    rescue
      puts "Error: ........ #{patient_attribute.inspect}"
    end

    begin
      if patient_attribute['name'] == 'Cell Phone Number'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @cell_phone_type.couchdb_person_attribute_type_id,
        value: patient_attribute['value'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @cell_phone_type.id)
      end
    rescue
      puts "Error: ........ #{patient_attribute.inspect}"
    end

    begin
      if patient_attribute['name'] == 'Home Phone Number'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @home_phone_type.couchdb_person_attribute_type_id,
        value: patient_attribute['value'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @home_phone_type.id)
      end
    rescue
      puts "Error: ........ #{patient_attribute.inspect}"
    end

    begin
      if patient_attribute['name'] == 'Office Phone Number'
        couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
        person_attribute_type_id: @work_phone_type.couchdb_person_attribute_type_id,
        value: patient_attribute['value'])
        push_to_person_attribute_sql_file(couchdb_person_attribute, @work_phone_type.id)
      end
    rescue
      puts "Error: ........ #{patient_attribute.inspect}"
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


  begin
    unless patient_addresses['home_district'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @home_district_type.couchdb_person_attribute_type_id,
      value: patient_addresses['home_district'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @home_district_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end
  
  begin 
    unless patient_addresses['home_ta'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @home_ta_type.couchdb_person_attribute_type_id,
      value: patient_addresses['home_ta'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @home_ta_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end
  
  begin 
    unless patient_addresses['home_village'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @home_village_type.couchdb_person_attribute_type_id,
      value: patient_addresses['home_village'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @home_village_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end
  
  begin 
    unless patient_addresses['current_district'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @current_district_type.couchdb_person_attribute_type_id,
      value: patient_addresses['current_district'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @current_district_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end
  
  begin 
    unless patient_addresses['current_ta'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @current_ta_type.couchdb_person_attribute_type_id,
      value: patient_addresses['current_ta'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @current_ta_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end
  
  begin 
    unless patient_addresses['current_village'].blank?
      couchdb_person_attribute = CouchdbPersonAttribute.create(person_id: couchdb_person.id, 
      person_attribute_type_id: @current_village_type.couchdb_person_attribute_type_id,
      value: patient_addresses['current_village'])
      push_to_person_attribute_sql_file(couchdb_person_attribute, @current_village_type.id)
    end
  rescue
    puts "Error ............ #{patient_addresses.inspect}"
  end

end

def push_to_people_sql_file(couchdb_person)
  File.open("#{Rails.root}/log/people.sql", "a+"){|f|
  
  died                  = couchdb_person['died'].blank? ? 'NULL' : couchdb_person['died']
  middle_name           = couchdb_person['middle_name'].blank? ? 'NULL' : '"' + couchdb_person['middle_name'] + '"'
  deathdate             = couchdb_person['deathdate'].blank? ? 'NULL' : "'#{couchdb_person['deathdate']}'"
  deathdate_estimated   = couchdb_person['deathdate_estimated'].blank? ? 'NULL' : couchdb_person['deathdate_estimated']

  if @first_loop == true
  string =<<EOF
(#{@sql_patient_id},"#{couchdb_person['_id']}", "#{couchdb_person['given_name']}", #{middle_name},"#{couchdb_person['family_name']}","#{couchdb_person['gender']}","#{couchdb_person['birthdate']}", #{couchdb_person['birthdate_estimated']},#{died},#{deathdate}, #{deathdate_estimated}, #{@location_created_at.id}, #{@user.id},"#{couchdb_person['created_at']}","#{couchdb_person['updated_at']}")
EOF
 
    @first_loop = false 
  else
    string =<<EOF
, (#{@sql_patient_id},"#{couchdb_person['_id']}", "#{couchdb_person['given_name']}", #{middle_name},"#{couchdb_person['family_name']}","#{couchdb_person['gender']}","#{couchdb_person['birthdate']}", #{couchdb_person['birthdate_estimated']},#{died},#{deathdate}, #{deathdate_estimated}, #{@location_created_at.id}, #{@user.id},"#{couchdb_person['created_at']}","#{couchdb_person['updated_at']}")
EOF
  end
    f << string
  }

end

def push_to_person_attribute_sql_file(couchdb, person_attribute_type_id)
  @sql_patient_attribute_id += 1
  File.open("#{Rails.root}/log/person_attributes.sql", "a+"){|f|
  
  if @first_loop2 == true
    string =<<EOF
(#{@sql_patient_attribute_id}, "#{couchdb['person_id']}", #{@sql_patient_id},"#{couchdb['person_attribute_type_id']}", #{person_attribute_type_id},"#{couchdb['person_attribute_id']}","#{couchdb['value']}","#{couchdb['created_at']}","#{couchdb['updated_at']}")
EOF

    @first_loop2 = false
  else
    string =<<EOF
, (#{@sql_patient_attribute_id}, "#{couchdb['person_id']}", #{@sql_patient_id},"#{couchdb['person_attribute_type_id']}", #{person_attribute_type_id},"#{couchdb['person_attribute_id']}","#{couchdb['value']}","#{couchdb['created_at']}","#{couchdb['updated_at']}")
EOF

  end

    f << string
  }
end

start
