module Api
  class UsersController < Api::ApplicationController
    load_and_authorize_resource
    around_action :accept_invitation, only: :create, unless: lambda { params[:invitation_token].nil? }
    around_action :create_provider, only: :create #, if: lambda { params[:create_provider].to_s.match(/^true$/i) }
    before_action :sanitize_email, only: [:create, :update, :reset_password]
    skip_before_action :authenticate_token!, only: [:create, :reset_password]

    def show
      respond_with(:api, @user)
    end

    def create
      user = User.find_by(email: params[:email])
      user_exists = !user.nil?
      force_upsert = user_exists && !params[:fb_user_id].nil? # facebook login attempts to create users repeatedly; we handle as forced upsert
      raise ActiveRecord::RecordNotUnique.new('email address taken') unless force_upsert
      if force_upsert
        @user = user
        return update
      end
      @user.save && true
      @token = Token.create(authenticable: @user) if @user.persisted?
      respond_with(:api, @user, template: 'api/users/create', status: :created)
    end

    def update
      @user.update(user_params)
      respond_with(:api, @user)
    end

    def reset_password
      user = User.find_by(email: params[:email])
      raise UnprocessableEntity unless user

      reset_password_token = params.delete(:reset_password_token)
      if reset_password_token
        raise UnprocessableEntity if user.reset_password_token != reset_password_token
        user.update(password: params[:password], reset_password_token: nil, reset_password_sent_at: nil)
      else
        user.reset_password
      end

      head :no_content
    end

    private

    def accept_invitation
      invitation_token = params.delete(:invitation_token)
      user = User.find_by(email: params[:email])
      invitation = user.invitations.select { |_invitation| _invitation.token == invitation_token }.first if user
      raise UnprocessableEntity unless invitation
      if invitation.accept
        @user = user
        @user.update_attributes(user_params) if @user
        @token = Token.create(authenticable: @user) if @user.persisted?
        respond_with(:api, @user, template: 'api/users/create', status: :created)
      else
        yield
      end
    end

    def create_provider
      yield
      return if @user.providers.size > 0
      provider = @user.providers.create
      timezone = TimeZone.find(params[:time_zone]) rescue (TimeZone.find(params[:contact][:time_zone_id]) rescue nil)
      Contact.create(contactable: provider,
                     name: params[:name],
                     email: params[:email],
                     time_zone: timezone,
                     time_zone_id: timezone) if provider && provider.contact.nil?
    end

    def sanitize_email
      params[:email] = params[:email].to_s.downcase if params[:email]
    end

    def user_params
      params[:contact_attributes] = params.delete(:contact) if params.key?(:contact)
      params[:contact_attributes] ||= { name: params[:name], email: params[:email], time_zone: params[:timezone], time_zone_id: params[:timezone] }
      params.permit(:name, :email, :password, { contact_attributes: permitted_contact_params },
                    :fb_user_id, :fb_access_token, :fb_access_token_expires_at)
    end
  end
end
