class LocationNpid < ApplicationRecord
  # Define the default scope
  default_scope { where(allocated: false, assigned: false) }
end
