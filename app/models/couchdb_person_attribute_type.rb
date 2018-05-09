class CouchdbPersonAttributeType < CouchRest::Model::Base
  property    :name,      String
  property    :voided,    TrueClass, default: false

  timestamps!
end
