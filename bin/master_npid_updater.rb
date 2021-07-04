require 'zlib'
require "people_matching_service/bantu_soundex"

config   = Rails.configuration.database_configuration
@username = config[Rails.env]["username"]
@password = config[Rails.env]["password"]
@database_main = config[Rails.env]["database"]
@batch_size = 25_000


def init_insert
	sql = "INSERT INTO `location_npids` (`location_id`, `npid`, `assigned`, `created_at`, `updated_at`) VALUES "
end

def load_file(db, file)  
  puts "loading #{file} into #{db}"
  infile = open(file)
  gz = Zlib::GzipReader.new(infile)

  statements = gz.split(/;$/)
  statements.pop

  db_con = ActiveRecord::Base.establish_connection({:username => @username,
                                                    :password => @password,
                                                    :database => db})

  ActiveRecord::Base.transaction do 
    statements.each do | statement |
      db_con.connection.execute(statement)
    end
  end
end

def load_dumps
  files = Dir.glob("#{Rails.root}/storage/*.gz")


  Parallel.each_with_index(files) do | file, i |

   sql = "CREATE DATABASE IF NOT EXISTS npid_update#{i};"

    ActiveRecord::Base.connection.execute(sql)
    puts "Loading #{file} into npid_update#{i}"
   `pv #{file} | gunzip | mysql -u#{@username} -p#{@password} npid_update#{i}`
  end
end

def save_person(person,db)
   person = format_person(person, db)
   begin
     PersonDetail.create!(person)
    rescue => e
      File.write("#{Rails.root}/log/error.log", e, mode: 'a')
    end
end

def format_person(person,db)
  #attributes = get_address(person['person_id'],db)
  person = {
    id:                     'NULL',
    first_name:             "\"#{person['given_name']}\"",
    last_name:              "\"#{person['family_name']}\"",
    middle_name:            "\"#{person['middle_name']}\"",
    birthdate:              ("\"#{person['birthdate'].to_date.strftime('%Y-%m-%d')}\"" rescue 'NULL'),
    birthdate_estimated:    person['birthdate_estimated'],
    gender:                 "\"#{person['gender']}\"",
    ancestry_district:      "\"#{person['ancestry_district']}\"",
    ancestry_ta:            "\"#{person['ancestry_ta']}\"",
    ancestry_village:       "\"#{person['ancestry_village']}\"",
    home_district:          "\"#{person['home_district']}\"",
    home_ta:                "\"#{person['home_ta']}\"",
    home_village:           "\"#{person['home_village']}\"",
    npid:                   "\"#{person['npid']}\"",
    person_uuid:            "\"#{person['couchdb_person_id']}\"",
    date_registered:        "\"#{person['created_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"",
    last_edited:            "\"#{person['updated_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"",
    location_created_at:    person['location_created_at'],
    location_updated_at:    person['location_created_at'],
    created_at:             'now()',
    updated_at:             'now()',
    creator:                person['creator'],
    voided:                 person['voided'],
    voided_by:              (person['voided_by'] || 'NULL'),
    date_voided:            ("\"#{person['date_voided'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"" rescue 'NULL'),
    void_reason:            "\"#{person['void_reason']}\"",
    first_name_soundex:     "\"#{person['given_name'].soundex}\"",
    last_name_soundex:      "\"#{person['family_name'].soundex}\""
  }
end

def batch_process(query)
  offset = 0
  begin
    batch = ActiveRecord::Base.connection.select_all <<-SQL
      #{query}
      LIMIT #{@batch_size}
      OFFSET #{offset}
    SQL
    batch.each do |row|
      yield row
    end
    offset += @batch_size
  end until batch.empty?
end

def import_non_duplicate_records(database)
  loaded_people = []
  loaded_npids  = []
  PersonDetail.unscoped.all.select(:person_uuid,:npid).each do |uuid|
    loaded_people << uuid['person_uuid']
    loaded_npids << uuid['npid']
  end

  select_people = %Q(SELECT * FROM #{database}.people pple LEFT JOIN
                    (
                    SELECT anc.person_id, anc.ancestry_district, anc_ta.ancestry_ta, anc_village.ancestry_village,
                    hme_district.home_district,
                    home_ta.home_ta,
                    hme_vllg.home_village
                    FROM
                    (SELECT pa.person_id, pa.value ancestry_district FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 4 and pa.voided = 0) anc
                    JOIN
                    (SELECT pa.person_id, pa.value ancestry_ta FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 5 and pa.voided = 0) anc_ta
                    ON anc.person_id = anc_ta.person_id
                    JOIN
                    (SELECT pa.person_id, pa.value ancestry_village FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 6 and pa.voided = 0) anc_village
                    ON anc.person_id = anc_village.person_id
                    JOIN
                    (SELECT pa.person_id, pa.value home_district FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 1 and pa.voided = 0) hme_district
                    ON anc.person_id = hme_district.person_id
                    JOIN
                    (SELECT pa.person_id, pa.value home_ta FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 2 and pa.voided = 0) home_ta
                    ON anc.person_id = home_ta.person_id
                    JOIN
                    (SELECT pa.person_id, pa.value home_village FROM #{database}.person_attributes pa
                    WHERE pa.person_attribute_type_id = 3 and pa.voided = 0) hme_vllg
                    ON anc.person_id = hme_vllg.person_id) attr
                    ON pple.person_id = attr.person_id
                    WHERE length(npid) > 0
                    AND given_name is not null
                    AND family_name is not null
                    )
  records = []
  batch_process(select_people) do | person|
     next if loaded_people.include?(person['couchdb_person_id']) || loaded_npids.include?(person['npid'])
     records << format_person(person,database)
     loaded_people << person['couchdb_person_id']
     loaded_npids << person['npid']
     #puts records.count
     if (records.size % @batch_size == 0)
        import_record(records)
        records = []
     end
  end
  import_record(records)
  records = []
end

def import_record(people)
  sql = build_sql_from_(people)
  ActiveRecord::Base.connection.execute(sql)
end

def build_sql_from_(people)
  sql = "INSERT INTO person_details VALUES"
  sql_values = []
  people.each do |person|
    sql_values << "(#{person.values.join(", ")})"
  end
  sql += sql_values.join(", ")
end


def main
    load_dumps

    site_databases = ActiveRecord::Base.connection.execute <<~SQL
      SHOW DATABASES LIKE 'npid_update%';
    SQL

    site_databases.each do | database |
      update_npids = "UPDATE #{@database_main}.npids SET assigned = 1 WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids);"

      ActiveRecord::Base.connection.execute(update_npids)

      unavailable_npids = "SELECT #{LocationNpid.column_names[1..7].join(', ')} FROM #{database[0]}.location_npids WHERE npid NOT IN (SELECT npid FROM #{@database_main}.location_npids) AND length(npid) <> 0;"

      un_npids = ActiveRecord::Base.connection.execute(unavailable_npids)

      sql_batch_insert = init_insert

      count = un_npids.count

      un_npids.each_with_index do |row, n|
        	row.each_with_index do | value, i |
        	 sql_batch_insert << "(\"#{value}\"," if i == 0
        	 sql_batch_insert << "\"#{value}\"," if i < 5 && i > 0
        	 sql_batch_insert << ("\"#{value.to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"," rescue "\"#{row[6].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\"," rescue '"1900-01-01 00:00:00",') if i == 5
        	 sql_batch_insert << ("\"#{value.to_datetime.strftime('%Y-%m-%d %H:%M:%S')}\")," rescue "\"#{row[5].strftime.to_datetime('%Y-%m-%d %H:%M:%S')}\")," rescue '"1900-01-01 00:00:00"),') if i == 6
        	end
        if n > 0
      	  if (n + 1) % @batch_size == 0 || count == n + 1
      	  	ActiveRecord::Base.connection.execute(sql_batch_insert.chomp!(','))
      	  	sql_batch_insert = init_insert
      	  end
        end
      end
      puts "updating location_npids assigned state for #{database[0]}"

      update_location_npid_state = "UPDATE #{@database_main}.location_npids SET assigned = 1 WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids WHERE assigned = 1);"

      ActiveRecord::Base.connection.execute(update_location_npid_state)
      begin
        import_non_duplicate_records(database[0])
      rescue => e
        File.write("#{Rails.root}/log/error.log",e,mode: 'a' )
      end

      # sql = "DROP database #{database[0]};"
      # puts "Cleaning #{database[0]}"
      # ActiveRecord::Base.connection.execute(sql)
    end
end

main



