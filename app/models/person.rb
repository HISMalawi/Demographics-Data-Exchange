class Person < ApplicationRecord
  after_create :update_footprint
  
  default_scope { where(voided: 0) }
 
  private
 
  def update_footprint
    FootPrintService.create(self)
  end
  
end 
