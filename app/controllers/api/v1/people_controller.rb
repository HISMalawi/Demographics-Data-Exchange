class Api::V1::PeopleController < ApplicationController
  def create
    person = PersonService.create(params)
    
  end
end
