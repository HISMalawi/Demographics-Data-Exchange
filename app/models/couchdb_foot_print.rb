class CouchdbFootPrint < CouchRest::Model::Base
  property  :npid,					String
  property  :user_id,				String
  property  :location_id,			String

  timestamps!
end
