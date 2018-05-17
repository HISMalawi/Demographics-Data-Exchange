class CouchdbPersonAttributeType < CouchRest::Model::Base
  property    :name,        String
  property    :voided,      TrueClass, default: false
  property    :void_reason, String

  timestamps!
end
