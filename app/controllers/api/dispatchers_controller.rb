module Api
  class DispatchersController < Api::ApplicationController
    around_action :associate_with_company, only: :create, unless: lambda { params[:company_id].nil? }
    around_action :send_invitation, only: :create, if: :invite_user?
    load_and_authorize_resource

    def index
      @dispatchers = filter_by(@dispatchers, indexes)
      respond_with(:api, @dispatchers)
    end

    def show
      respond_with(:api, @dispatcher)
    end

    def create
      @dispatcher.save && true
      respond_with(:api, @dispatcher, template: 'api/dispatchers/show', status: :created)
    end

    def update
      @dispatcher.update(dispatcher_params)
      respond_with(:api, @dispatcher)
    end

    def destroy
      @dispatcher.destroy
      respond_with(:api, @dispatcher)
    end

    private

    def associate_with_company
      yield
      @dispatcher.company.dispatchers << @dispatcher if @dispatcher.persisted?
    end

    def indexes
      [:company_id, :user_id]
    end

    def invite_user?
      user = params[:user_id] ? User.find(params[:user_id]) : nil
      return false if user
      user = User.where(email: params[:contact][:email]).first if params[:contact] && params[:contact][:email]
      user.nil?
    end

    def send_invitation
      yield
      send_invites = @dispatcher.user && @dispatcher.persisted?
      @dispatcher.user.invitations.create(sender: current_user) if send_invites
      @dispatcher.user.invitations.create(type: :pin, sender: current_user) if send_invites && @dispatcher.contact && @dispatcher.contact.mobile
    end

    def dispatcher_params
      params[:contact_attributes] = params.delete(:contact) if params.key? :contact
      params.permit(
        :company_id, { contact_attributes: permitted_contact_params }, :user_id
      )
    end
  end
end
