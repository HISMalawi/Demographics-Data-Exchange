def migrate_npids
  npid_type   = ActiveRecord::Base.connection.select_one <<EOF
  	SELECT * FROM person_attribute_types WHERE name = "National patient identifier"
EOF
  attr_type_id = npid_type['person_attribute_type_id']

  attributes = ActiveRecord::Base.connection.select_all <<EOF
  	SELECT * from person_attributes WHERE person_attribute_type_id = "#{attr_type_id}"
EOF

  (attributes || []).each do |attribute|
    couch_person_id	= attributes['couchdb_person_id']

    person = CouchdbPerson.find(couch_person_id)
    unless person.blank?
      person.update_attributes(npid: attribute['value'])
=begin
	  person.npid = attribute['value']
	  person.save
=end
    end
  end
end

migrate_npids