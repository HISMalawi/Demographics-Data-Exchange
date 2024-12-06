class LocationNpid < ApplicationRecord
  # Set the default scope
  default_scope { where(allocated: false, assigned: false) }
end
