class CouchdbUser < CouchRest::Model::Base

  property  :email,             String
  property  :password_digest,   String
  property  :voided,            TrueClass
  
  timestamps!

    
end
