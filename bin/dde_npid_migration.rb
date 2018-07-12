couchdb_yml = Rails.root.to_s + "/config/couchdb.yml"
env = Rails.env
couch_db_settings = YAML.load_file(couchdb_yml)[env]

couch_host = couch_db_settings["host"]
couch_prefix = couch_db_settings["prefix"]
couch_suffix = couch_db_settings["suffix"]
couch_db = couch_prefix.to_s + "_" + couch_suffix
couch_port = couch_db_settings["port"]

couch = CouchRest.new("http://#{couch_host}:#{couch_port}")
@db = couch.database("#{couch_db}")

def start
  npid_type = ActiveRecord::Base.connection.select_one <<EOF
  	SELECT * FROM person_attribute_types WHERE name = "National patient identifier"
EOF
  attr_type_id = npid_type['person_attribute_type_id'].to_i

  attributes = ActiveRecord::Base.connection.select_all <<EOF
	SELECT couchdb_person_attribute_id, couchdb_person_id, value, count(value) c from person_attributes 
	WHERE person_attribute_type_id = #{attr_type_id}
	GROUP BY value HAVING c < 2;
EOF

  (attributes || []).each do |attribute|
    couch_person_id	= attribute['couchdb_person_id']

    person = CouchdbPerson.find(couch_person_id)
    unless person.blank?
      person.update_attributes(npid: attribute['value'])
      ActiveRecord::Base.connection.execute <<EOF
      DELETE FROM person_attributes WHERE 
      couchdb_person_attribute_id = "#{attribute['couchdb_person_attribute_id']}"
      AND couchdb_person_id = "#{couch_person_id}"
EOF

      doc = @db.get(attribute['couchdb_person_attribute_id'])
      @db.delete_doc(doc)

			puts "Moved: #{attribute['value']} ..."
    end
  end
end


start
