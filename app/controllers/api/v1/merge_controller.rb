class Api::V1::MergeController < ApplicationController
  
  def merge
    merged_person = MergeService.merge(params[:primary_person_doc_id], params[:secondary_person_doc_id])
    render plain: merged_person.to_json
  end

end
