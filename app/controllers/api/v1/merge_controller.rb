class Api::V1::MergeController < ApplicationController
  def merge
    merged_person = MergeService.merge(params[:primary_person_doc_id], params[:secondary_person_doc_id], current_user)
    render json: merged_person
  end
end
