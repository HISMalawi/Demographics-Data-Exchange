class Person < ApplicationRecord
  def self.search_by_name_and_gender(params)
    given_name = params[:given_name]
    family_name = params[:family_name]
    gender = params[:gender]
    
    people = Person.where(["given_name =? AND family_name =? AND gender =?", 
      given_name, family_name, gender])
    return people
  end
end
