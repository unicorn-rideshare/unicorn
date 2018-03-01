module Unicorn
  module TokenAuthenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_token
      append_before_action :authenticate_jwt
    end

    private

    def api_authorization_cookie
      authorization = nil
      request.cookies.each do |name, value|
        authorization = Base64.urlsafe_decode64(value).split(':') rescue [nil, nil] if name.match(/x-api-authorization/i)
      end
      authorization
    end

    def api_authorization_header
      authorization = request.headers['x-api-authorization']
      return unless authorization
      match_data = authorization.match(/^Basic[\s]+(.+)$/)
      hashed_token = match_data ? match_data[1] : authorization
      Base64.urlsafe_decode64(hashed_token).split(':') rescue [nil, nil]
    end

    def api_authorization_param
      Base64.urlsafe_decode64(params['x-api-authorization']).split(':') rescue [nil, nil]
    end

    def authenticate_token!
      head :unauthorized unless authenticable
    end

    def authenticate_token
      token_s, uuid = api_authorization_header || api_authorization_cookie || api_authorization_param
      @current_token = Token.find_by_token(token_s) if token_s && uuid
      instance_variable_set("@current_#{@current_token.authenticable_type.downcase}", @current_token.authenticable) if @current_token && @current_token.authenticate(uuid)
    end

    def authenticate_jwt!
      head :unauthorized if jwt_token.nil?
    end

    def authenticate_jwt
      return if current_user || jwt_token.nil?
      @current_jwt_authenticable = begin
        @current_jwt_token = JwtToken.authenticate(jwt_token)
        authenticable = @current_jwt_token.try(:authenticable)
        instance_variable_set("@current_#{authenticable.class.name.underscore}", authenticable)
        @current_user = authenticable.try(:user) unless (current_user rescue nil)
        authenticable
      end

      head :unauthorized if @current_jwt_authenticable.nil?
    end

    def jwt_token
      @jwt_token ||= begin
        authorization = request.headers['x-jwt-token']
        unless authorization
          authorization = request.headers['authorization']
          authorization = authorization.gsub(/^bearer[\s]+(.*)/, '\1') if authorization
        end
        authorization
      end
    end

    def authenticable
      @current_jwt_authenticable || current_user || current_company
    end

    def current_ability
      @current_ability ||= Ability.new(authenticable, params)
    end

    def current_user
      @current_user
    end

    def current_company
      @current_company
    end

    def current_token
      @current_token
    end
  end
end
