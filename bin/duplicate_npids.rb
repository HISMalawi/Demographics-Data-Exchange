def get_mysql_npids
  mysql_npids = Person.all.where("NOT ISNULL(npid)")
end

def get_couchdb_npids(npid)
  puts "checking #{npid}"
  couchdb_npids = `curl -H "Content-Type: application/json" -X POST "admin:password@localhost:5984/dde3_dev/_find?include_docs=true" -d '{"selector":{"npid": "#{npid}","type": "CouchdbPerson"}}'`
  couchdb_npids = JSON.parse(couchdb_npids)
  return couchdb_npids["docs"]
end

def fix_duplicates()
  #Create couchdb person_attribute
  response =
end

def check_for_duplicates(npids)
  npids.each_with_index do |mysql_record, i|
     #Check with couchdb
    couchdb_records = get_couchdb_npids(mysql_record[:npid])
    couchdb_records.each do |couchdb_record|
      puts "#{mysql_record[:npid]},#{mysql_record[:couchdb_person_id]},#{couchdb_record["_id"]}"
      if mysql_record[:couchdb_person_id]  != couchdb_record["_id"]
        `echo "#{mysql_record[:npid]},#{mysql_record[:couchdb_person_id]},#{couchdb_record["_id"]}" >> #{Rails.root}/log/conflict_npids.log`
      end
    end
    puts "Processed #{i} of #{npids.length}"
  end
end

def start
  check_for_duplicates(get_mysql_npids)
end

start