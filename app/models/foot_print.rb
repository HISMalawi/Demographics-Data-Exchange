class FootPrint < ApplicationRecord
  self.primary_key = 'foot_print_id'
  
  validates :encounter_datetime, presence: true
end
