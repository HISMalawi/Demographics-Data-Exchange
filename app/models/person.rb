class Person < ApplicationRecord
  after_create :update_footprint
 
  private
 
  def update_footprint
    FootPrintService.create(self)
  end
  
end 
