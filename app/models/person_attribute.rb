class PersonAttribute < ApplicationRecord
  
  default_scope { where(voided: 0) }

end
