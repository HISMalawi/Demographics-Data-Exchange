class CouchdbUser < CouchRest::Model::Base

  property  :username,          String
  property  :email,             String
  property  :password_digest,   String
  property  :voided,            TrueClass, default: false
  property  :void_reason,       String
  property  :location_id,       String
  
  timestamps!

end
