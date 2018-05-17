class CouchdbPersonAttribute < CouchRest::Model::Base
  property      :person_id,                         String
  property      :person_attribute_type_id,          String
  property      :value,                             String
  property      :voided,                            TrueClass, default: false
  property      :voided_by,                         String
  property      :date_voided,                       DateTime
  property      :void_reason,                       String

  timestamps!
end
