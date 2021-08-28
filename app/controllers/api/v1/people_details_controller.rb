class Api::V1::PeopleDetailsController < ApplicationController
  before_action :set_api_v1_people_detail, only: [:show, :update, :destroy]

  # GET /api/v1/people_details
  def index
    @api_v1_people_details = Api::V1::PeopleDetail.all

    render json: @api_v1_people_details
  end

  # GET /api/v1/people_details/1
  def show
    render json: @api_v1_people_detail
  end

  # POST /api/v1/people_details
  def create

    errors = ValidateParams.add_person(params)
    if errors.blank?
      person = PersonService.create(params, current_user)
      render json: person
    else
      render json: errors
    end
  end

  # PATCH/PUT /api/v1/people_details/1
  def update_person
    errors = ValidateParams.update_person(params)
    if errors.blank?
      person = PersonService.update_person(params, current_user)
      render json: person
    else
      render json: errors
    end
  end

 #Search by name and gender
 def search_by_name_and_gender
    errors = ValidateParams.search_by_name_and_gender(params)
    if errors.blank?
      search_results = PersonService.search_by_name_and_gender(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def search_by_npid
   errors = ValidateParams.search_by_npid(params)
   if errors.blank?
     search_results = PersonService.search_by_npid(params)
     render json: search_results
   else
     render json: errors
   end
  end

   def search_by_doc_id
    errors = ValidateParams.search_by_doc_id(params)
    if errors.blank?
      search_results = PersonService.search_by_doc_id(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def merge_people
    errors = ValidateParams.merge_people(params)
    if errors.blank?
      merge_results = MergeService.merge(params[:primary_person_doc_id], params[:secondary_person_doc_id],current_user)
      render json: merge_results
    else
      render json: errors
    end
  end

  def reassign_npid
    person = PersonService.reassign_npid(params, current_user)
    render json: person
  end

  def void
    person = PersonService.void_person(void_params,current_user)
    unless person.blank?
      render json: person, status: :ok
    else
      render json: {error: 'something went wrong'},  status: :internal_server_error
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_v1_people_detail
      @api_v1_people_detail = Api::V1::PeopleDetail.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def api_v1_people_detail_params
      params.fetch(:api_v1_people_detail, {})
    end

    def void_params
      params.require(:void_reason)
      {person_uuid: params[:person_uuid], void_reason: params[:void_reason]}
    end
end
