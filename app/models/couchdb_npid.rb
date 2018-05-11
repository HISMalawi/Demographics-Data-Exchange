class CouchdbNpid < CouchRest::Model::Base
  property :npid,  			String
  property :version_number, String
  property :assigned,       TrueClass, default: false

  timestamps!
end