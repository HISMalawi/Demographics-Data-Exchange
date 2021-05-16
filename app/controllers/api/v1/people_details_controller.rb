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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_v1_people_detail
      @api_v1_people_detail = Api::V1::PeopleDetail.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def api_v1_people_detail_params
      params.fetch(:api_v1_people_detail, {})
    end
end