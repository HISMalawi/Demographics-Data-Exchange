require 'zlib'

config   = Rails.configuration.database_configuration
@username = config[Rails.env]["username"]
@password = config[Rails.env]["password"]
@database_main = config[Rails.env]["database"]
@batch_size = 1_000


def init_insert
	sql = "INSERT INTO `location_npids` (`location_id`, `npid`, `assigned`,`created_at`, `updated_at`) VALUES "
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


files = Dir.glob("#{Rails.root}/storage/*.gz")


Parallel.each_with_index(files) do | file, i |
	
 sql = "CREATE DATABASE IF NOT EXISTS npid_update#{i};"

  ActiveRecord::Base.connection.execute(sql)
  puts "Loading #{file} into npid_update#{i}"
 `pv #{file} | gunzip | mysql -u#{@username} -p#{@password} npid_update#{i}`
end
  site_databases = ActiveRecord::Base.connection.execute <<~SQL
    SHOW DATABASES LIKE 'npid_update%';
  SQL

  site_databases.each_with_index do | database, i |
    puts "updating database #{i} / #{site_databases.count} named #{database[0]}"

    ActiveRecord::Base.connection.execute("ALTER TABLE #{database[0]}.location_npids add index(npid)")

    ActiveRecord::Base.connection.execute("ALTER TABLE #{database[0]}.people add index(npid)")

    update_npids = "UPDATE #{@database_main}.npids SET assigned = true WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids);"

    ActiveRecord::Base.connection.execute(update_npids)

    update_npids = "UPDATE #{@database_main}.npids SET assigned = true WHERE npid IN (SELECT npid FROM #{database[0]}.people where npid is not null);"

    ActiveRecord::Base.connection.execute(update_npids)

    unavailable_npids = "SELECT * FROM #{database[0]}.location_npids WHERE npid NOT IN (SELECT npid FROM #{@database_main}.location_npids) AND length(npid) = 6;"
    
    un_npids = ActiveRecord::Base.connection.exec_query(unavailable_npids)
    sql_batch_insert = init_insert

    count = un_npids.count

    un_npids.each_with_index do |row, n|
         sql_batch_insert << '(' + row['location_id'].to_s + ','
      	 sql_batch_insert <<  "'#{row['npid']}',"
      	 sql_batch_insert << "#{row['assigned']},"
      	 sql_batch_insert << ("'#{row['created_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}'," rescue "'#{row['updated_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}'," rescue '"1900-01-01 00:00:00",')
      	 sql_batch_insert << ("'#{row['updated_at'].to_datetime.strftime('%Y-%m-%d %H:%M:%S')}')," rescue "'#{row['created_at'].strftime.to_datetime('%Y-%m-%d %H:%M:%S')}')," rescue '"1900-01-01 00:00:00"),')
      if n > 0
    	  if (n + 1) % @batch_size == 0 || count == n + 1 
    	  	ActiveRecord::Base.connection.execute(sql_batch_insert.chomp!(','))
    	  	sql_batch_insert = init_insert
    	  end
      end
    end
    puts "updating location_npids assigned state for #{database[0]}"
    
    update_location_npid_state = "UPDATE #{@database_main}.location_npids SET assigned = true WHERE npid IN (SELECT npid FROM #{database[0]}.location_npids WHERE assigned = true);"
    
    ActiveRecord::Base.connection.execute(update_location_npid_state)

    update_location_npid_state = "UPDATE #{@database_main}.location_npids SET assigned = true WHERE npid IN (SELECT npid FROM #{database[0]}.people WHERE npid is not null);"

    ActiveRecord::Base.connection.execute(update_location_npid_state)

    ActiveRecord::Base.connection.execute("INSERT INTO location_npids (location_id,npid,assigned,created_at,updated_at) select 1077,n.npid,n.assigned,now(),now() from
npids n left join location_npids ln on n.npid = ln.npid WHERE ln.npid is null and n.assigned = true;")

    # sql = "DROP database #{database[0]};"
    # puts "Cleaning #{database[0]}"
    # ActiveRecord::Base.connection.execute(sql)
  end



