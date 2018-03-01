module Api
  class InvitationsController < Api::ApplicationController
    before_action :load_invitation_by_pin
    skip_before_action :authenticate_token!, only: [:show]

    def show
      respond_with(:api, @user)
    end

    private

    def load_invitation_by_pin
      @invitation = Invitation.unscoped.where(token: params[:id]).first unless @invitation
      raise ActiveRecord::RecordNotFound unless @invitation
      raise ActiveRecord::RecordNotFound if @invitation && (!@invitation.is_pin? || @invitation.expired? || @invitation.accepted?)
    end
  end
end
