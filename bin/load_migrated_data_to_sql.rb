def start
  i = 1
  data = ''
  File.open("#{Rails.root}/log/people.sql", 'r').each_line do |line|
    puts "Processing record #{i}"
    data += "(#{line}),"
    if (i % 50_000).zero? || 2_332_908 == i
      puts 'Loading data into MySQL'
      begin
        ActiveRecord::Base.connection.execute <<EOF
      	  INSERT INTO people (person_id, couchdb_person_id, 
          given_name,middle_name,family_name,gender,birthdate,
          birthdate_estimated,died,deathdate,deathdate_estimated,
          location_created_at, creator,created_at,updated_at) VALUES #{data};
EOF
      rescue StandardError => e
        `echo "#{e}" >> #{Rails.root}/log/dde_load_migrated_data_errors.log`
      end
      data.clear
    end
    i += 1
  end
end

start