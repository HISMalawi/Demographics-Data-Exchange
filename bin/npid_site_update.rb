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
  puts "updating database #{i + 1} / #{site_databases.count} named #{database[0]}"


  puts 'update location_npids from site database' 

  sql = "update #{@database_main}.location_npids set assigned = true
    WHERE npid in (select DISTINCT identifier from #{database[0]}.patient_identifier);"

  updated = ActiveRecord::Base.connection.execute(sql)


  puts "#{database[0]} update summary: #{updated}"

  sql = "update #{@database_main}.npids set assigned = true
         where npid in (select DISTINCT identifier from #{database[0]}.patient_identifier);"

  updated = ActiveRecord::Base.connection.execute(sql)


  puts "#{database[0]} update summary: #{updated}"

    sql = "DROP database #{database[0]};"
    puts "Cleaning #{database[0]}"
    ActiveRecord::Base.connection.execute(sql)
end



