def start
  i = 1
  data = ''
  File.open("#{Rails.root}/log/person_attributes.sql", 'r').each_line do |line|
    puts "Processing record #{i}"
    data += line
    if (i % 50_000).zero? || 18_928_998 == i
      puts 'Loading data into MySQL'
      stmt = <<EOF
	INSERT INTO person_attributes (person_attribute_id, couchdb_person_id, 
	person_id, couchdb_person_attribute_type_id, person_attribute_type_id, 
	couchdb_person_attribute_id, value, created_at, updated_at) VALUES
EOF
     if i > 50_000
       stmt += data[1..-1]
     else
       stmt += data
     end
     stmt += ";"
     
     File.open("#{Rails.root}/log/dump.sql", "w"){|f|
       f << stmt
     }

      begin
	`mysql -u root -proot dde_development < #{Rails.root}/log/dump.sql`
=begin
        ActiveRecord::Base.connection.execute <<EOF
      	  INSERT INTO people (person_id, couchdb_person_id, 
          given_name,middle_name,family_name,gender,birthdate,
          birthdate_estimated,died,deathdate,deathdate_estimated,
          location_created_at, creator,created_at,updated_at) VALUES #{data};
EOF
=end

      rescue StandardError => e
        `echo "#{e}" >> #{Rails.root}/log/dde_load_migrated_data_errors.log`
      end
      data.clear
    end
    i += 1
  end
end

start
