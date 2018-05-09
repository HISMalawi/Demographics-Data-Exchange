class Api::V1::PeopleController < ApplicationController
  
  def create
    person = PersonService.create(params, current_user)
    render plain: person.to_json    
  end



end
