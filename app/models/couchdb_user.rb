class CouchdbUser < CouchRest::Model::Base

  property  :username,          String
  property  :email,             String
  property  :password_digest,   String
  property  :voided,            TrueClass
  property  :location_id,       String
  
  timestamps!

    
end
