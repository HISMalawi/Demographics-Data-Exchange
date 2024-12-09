class LocationNpid < ApplicationRecord
  scope :unallocated_and_unassigned, -> { where(allocated: false, assigned: false)}
end
  