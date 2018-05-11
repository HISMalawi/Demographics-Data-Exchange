class CouchdbLocationNpid < CouchRest::Model::Base
	
  property  :assigned,            TrueClass, default: false
  property  :couchdb_location_id, String     
  property  :npid,                String

  timestamps!

end
