class CouchdbLocationNpid < CouchRest::Model::Base
	
  property  :assigned,            TrueClass, default: false
  property  :location_id, String     
  property  :npid,                String

  timestamps!

end
