require 'zlib'

config   = Rails.configuration.database_configuration
@username = config[Rails.env]["username"]
@password = config[Rails.env]["password"]
@database_main = config[Rails.env]["database"]
@batch_size = 1_000


def init_insert
	sql = "INSERT INTO `location_npids` (`couchdb_location_npid_id`, `couchdb_location_id`, `location_id`, `npid`, `assigned`,`created_at`, `updated_at`) VALUES "
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

def import_non_duplicate_records(database)
  select_people = "SELECT * FROM #{database.}.people WHERE npid is not null"

  people = ActiveRecord::Base.connection.execute(select_people)

  people.each do | person |

  end
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

      import_non_duplicate_records(database)

      # sql = "DROP database #{database[0]};"
      # puts "Cleaning #{database[0]}"
      # ActiveRecord::Base.connection.execute(sql)
    end
end

main



