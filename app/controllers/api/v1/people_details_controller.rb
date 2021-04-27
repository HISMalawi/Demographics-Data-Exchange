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
    debugger
    errors = ValidateParams.add_person(params)
    if errors.blank?
      person = PersonService.create(params, current_user)
      render json: person
    else
      render json: errors
    end
    # @api_v1_people_detail = Api::V1::PeopleDetail.new(api_v1_people_detail_params)

    # if @api_v1_people_detail.save
    #   render json: @api_v1_people_detail, status: :created, location: @api_v1_people_detail
    # else
    #   render json: @api_v1_people_detail.errors, status: :unprocessable_entity
    # end
  end

  # PATCH/PUT /api/v1/people_details/1
  def update
    if @api_v1_people_detail.update(api_v1_people_detail_params)
      render json: @api_v1_people_detail
    else
      render json: @api_v1_people_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/people_details/1
  def destroy
    @api_v1_people_detail.destroy
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
