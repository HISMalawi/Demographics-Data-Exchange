require 'rest-client'
require 'json'

couchdb_yml = Rails.root.to_s + "/config/couchdb.yml"
env = Rails.env
couch_db_settings = YAML.load_file(couchdb_yml)[env]

@couch_host = couch_db_settings["host"]
couch_prefix = couch_db_settings["prefix"]
couch_suffix = couch_db_settings["suffix"]
@couch_db = couch_prefix.to_s + "_" + couch_suffix
@couch_port = couch_db_settings["port"]
@skip = 0

def start
  (1..426).each do |i|
  	puts "Getting records ### #{@skip}"
  	data = get_data(@skip)
	(data || []).each do |d|
	  doc = d["doc"]
	  next unless (doc['type'] == "CouchdbPersonAttribute")
	  couchdb_attribute_id = doc['_id']
	  couchdb_attribute_type_id = doc['person_attribute_type_id']
	  couchdb_person_id = doc['person_id']

	  ActiveRecord::Base.connection.execute <<EOF
	    UPDATE person_attributes SET couchdb_attribute_id = couchdb_attribute_id
	    WHERE couchdb_person_id = couchdb_person_id
	    AND couchdb_person_attribute_type_id = couchdb_attribute_type_id
	  EOF
	  puts "Updating #{couchdb_person_id}"
	end
  	@skip += 50_000
  end
end

def get_data(skip = 0)
  url = "http://#{@couch_host}:#{@couch_port}/#{@couch_db}/_all_docs?include_docs=true&limit=50000&skip=#{skip}"
  data = JSON.parse(RestClient.get(url, content_type: :json))['rows']
end

start