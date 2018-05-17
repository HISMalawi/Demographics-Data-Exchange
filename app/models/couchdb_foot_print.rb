class CouchdbFootPrint < CouchRest::Model::Base
  property  :person_id,			String
  property  :user_id,				String
  
  timestamps!
end
