class Api::V1::MergeController < ApplicationController
  def merge
    merged_person = MergeService.merge(merge_params[:primary_person_doc_id], merge_params[:secondary_person_doc_id], current_user)
    render json: merged_person
  end

  def rollback_merge
    merge_rollback = MergeService.rollback_merge(merge_params[:primary_person_doc_id],merge_params[:secondary_person_doc_id], current_user)  
  end

  private
    def merge_params
      params.require([:primary_person_doc_id, :secondary_person_doc_id])
      param.permit(:primary_person_doc_id, :secondary_person_doc_id)
    end
end
