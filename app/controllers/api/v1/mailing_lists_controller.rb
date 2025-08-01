class Api::V1::MailingListsController < ApplicationController
  before_action :set_mailing_list, only: [:show, :update, :destroy]
  before_action :authorize_system_user

  skip_before_action :authenticate_request

  # GET v1/mailing_lists
  def index
    @mailing_lists = MailingList.joins(:roles)
                                .select("mailing_lists.*, roles.role")

    render json: @mailing_lists
  end

  # GET v1/mailing_lists/1
  def show
    render json: @mailing_list
  end

  # POST v1//mailing_lists
  def create
    if MailingList.exists?(email: mailing_list_params[:email])
      render json: { error: 'Email already exists' }, status: :ok
      return
    end

    @mailing_list = MailingList.new(mailing_list_params)

    if @mailing_list.save
      render json: @mailing_list, status: :created
    else
      render json: @mailing_list.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT v1//mailing_lists/1
  def update
    if mailing_list_params[:email].present? && MailingList.where(email: mailing_list_params[:email]).where.not(id: @mailing_list.id).exists?
      render json: { error: 'Email already exists' }, status: :ok
      return
    end

    if @mailing_list.update(mailing_list_params)
      render json: @mailing_list
    else
      render json: @mailing_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /mailing_lists/1
  def destroy
    @mailing_list.update(deactivated: true)
  end

  def roles
    @roles = Role.all

    render json: @roles
  end 

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mailing_list
      @mailing_list = MailingList.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def mailing_list_params
      params.permit(:id, :first_name, :last_name, :email, :phone_number, :role_id, )
    end
end
