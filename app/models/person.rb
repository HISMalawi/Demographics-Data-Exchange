class Person < ApplicationRecord
  
  def self.search_by_name_and_gender(params)
    given_name = params[:given_name]
    family_name = params[:family_name]
    gender = params[:gender]
    
    people = Person.where(["given_name =? AND family_name =? AND gender =?", 
      given_name, family_name, gender])
    return people
  end
  
  def self.search_by_npid(params)
    npid = params[:npid]
    doc_id = params[:doc_id]
    
    if doc_id.blank?
      people = Person.where(["npid =?", npid])
    else
      people = Person.where(["npid =? AND couchdb_person_id =?", npid, doc_id])
    end
    
    return people
  end
  
  def self.search_by_doc_id(params)
    doc_id = params[:doc_id]
    people = Person.where(["couchdb_person_id =?", doc_id])
    return people
  end
  
  def self.search_by_attributes(params)
    values = params[:values]
    
    if !(values.is_a?(Array))
      values = []
    end
    
    if values.blank?
      values = []
    end
    
    people = PersonAttribute.where(["value IN (?)", values])
    return people
  end
  
end
