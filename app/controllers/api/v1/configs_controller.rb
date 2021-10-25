class Api::V1::ConfigsController < ApplicationController
  before_action :set_api_v1_config, only: [:show, :update, :destroy]

  # GET /api/v1/configs
  def index
    @api_v1_configs = Api::V1::Config.all

    render json: @api_v1_configs
  end

  # GET /api/v1/configs/1
  def show
    render json: @api_v1_config
  end

  # POST /api/v1/configs
  def create
    @api_v1_config = Api::V1::Config.new(api_v1_config_params)

    if @api_v1_config.save
      render json: @api_v1_config, status: :created, location: @api_v1_config
    else
      render json: @api_v1_config.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/configs/1
  def update
    if @api_v1_config.update(api_v1_config_params)
      render json: @api_v1_config
    else
      render json: @api_v1_config.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/configs/1
  def destroy
    @api_v1_config.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_v1_config
      params.require(:config)
      @api_v1_config = Config.find_by_config(params[:config])
    end

    # Only allow a trusted parameter "white list" through.
    def api_v1_config_params
      params.permit(:config_value)
    end
end
