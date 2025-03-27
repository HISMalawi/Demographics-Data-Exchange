class MailingListsController < ApplicationController
  before_action :set_mailing_list, only: [:show, :update, :destroy]
  skip_before_action :authenticate_request

  # GET /mailing_lists
  def index
    @mailing_lists = MailingList.all

    render json: @mailing_lists
  end

  # GET /mailing_lists/1
  def show
    render json: @mailing_list
  end

  # POST /mailing_lists
  def create
    @mailing_list = MailingList.new(mailing_list_params)

    if @mailing_list.save
      render json: @mailing_list, status: :created, location: @mailing_list
    else
      render json: @mailing_list.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /mailing_lists/1
  def update
    if @mailing_list.update(mailing_list_params)
      render json: @mailing_list
    else
      render json: @mailing_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /mailing_lists/1
  def destroy
    @mailing_list.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mailing_list
      @mailing_list = MailingList.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def mailing_list_params
      params.require(:mailing_list).permit(:first_name, :last_name, :email, :phone_number)
    end
end
