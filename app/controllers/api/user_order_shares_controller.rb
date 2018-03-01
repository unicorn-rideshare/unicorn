class Api::UserOrderSharesController < Api::ApplicationController
  load_resource
  skip_before_action :authenticate_user!, :authenticate_token!

  def index
    @user_order_shares = filter_by(@user_order_shares, indexes)
    respond_with(:api, @user_order_shares)
  end

  def create
    @user_order_share.save && true
    respond_with(:api, @user_order_share, template: 'api/user_order_shares/show', status: :created)
  end

  private

  def indexes
    [:fb_user_id]
  end

  def user_order_share_params
    params.permit(:fb_user_id, :work_order_id)
  end
end
