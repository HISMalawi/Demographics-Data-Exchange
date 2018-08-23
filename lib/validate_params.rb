module ValidateParams
  def self.add_person(params)
    missing_parameters = []
    missing_parameters << "given_name" if params[:given_name].blank?
    missing_parameters << "family_name" if params[:family_name].blank?
    missing_parameters << "gender" if params[:gender].blank?
    missing_parameters << "birthdate" if params[:birthdate].blank? 
    missing_parameters << "birthdate_estimated" if params[:birthdate_estimated].blank? 
    
    unless params[:attributes].blank?
      missing_parameters << "home_district" if params[:attributes][:home_district].blank?
      missing_parameters << "home_village" if params[:attributes][:home_village].blank?
      missing_parameters << "home_traditional_authority" if params[:attributes][:home_traditional_authority].blank?
      #missing_parameters << "current_district" if params[:attributes][:current_district].blank?
      #missing_parameters << "current_village" if params[:attributes][:current_village].blank?
      #missing_parameters << "current_traditional_authority" if params[:attributes][:current_traditional_authority].blank?
      
    else
      missing_parameters << "attributes"
    end
    
    return [] if missing_parameters.blank?
    return {status: 400, message: "Missing the following parameters: #{missing_parameters.join(', ')}"}
    
  end
  
  def self.search_by_name_and_gender(params)
    missing_parameters = []
    missing_parameters << "given_name" if params[:given_name].blank?
    missing_parameters << "family_name" if params[:family_name].blank?
    missing_parameters << "gender" if params[:gender].blank?

    return [] if missing_parameters.blank?
    return {status: 400, message: "Missing the following parameters: #{missing_parameters.join(', ')}"}
  end
  
  def self.search_by_npid(params)
    missing_parameters = []
    missing_parameters << "npid" if params[:npid].blank?
    return [] if missing_parameters.blank?
    return {status: 400, message: "Missing the following parameters: #{missing_parameters.join(', ')}"}
  end
  
  def self.search_by_doc_id(params)
    missing_parameters = []
    missing_parameters << "doc_id" if params[:doc_id].blank?
    return [] if missing_parameters.blank?
    return {status: 400, message: "Missing the following parameters: #{missing_parameters.join(', ')}"}
  end
  
  def self.search_by_attributes(params)
    if params[:values].blank?
      return {status: 400, message: "Missing values"}
    end
    return []
  end
  
  def self.update_person(params)
    if params[:doc_id].blank?
      return {status: 400, message: "Missing doc_id"}
    end
    return []
  end
  
  def self.potential_duplicates(params)
    if params[:npid].blank?
      return {status: 400, message: "Missing npid"}
    end
    return []
  end
  
  def self.merge_people(params)
    missing_parameters = []
    missing_parameters << "primary_npid" if params[:primary_npid].blank?
    missing_parameters << "secondary_npid" if params[:secondary_npid].blank?
    
    return [] if missing_parameters.blank?
    return {status: 400, message: "Missing the following parameters: #{missing_parameters.join(', ')}"}
  end
  
end