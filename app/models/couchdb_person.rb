class CouchdbPerson < CouchRest::Model::Base
  property  :given_name, String
  property  :middle_name, String
  property  :family_name, String
  property  :gender,  String
  property  :birthdate,   Date, default: ""
  property  :birthdate_estimated,   TrueClass, default: false
  property  :died,                  TrueClass, default: false
  property  :deathdate,   Date
  property  :deathdate_estimated,   TrueClass, default: false
  property  :voided,                TrueClass, default: false
  property  :date_voided,           Date
  property  :npid,   String
  property  :location_created_at,   String
  property  :creator,               String

  timestamps!
end
