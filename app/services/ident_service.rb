class IdentService
  class << self

    def ident(jwt_token)
      Provide::Services::Ident.new((ENV['IDENT_API_SCHEME'] || 'http'), ENV['IDENT_API_HOST'], jwt_token)
    end

    def create_application(jwt_token, params)
      ident(jwt_token).create_application(params)
    end

    def applications(jwt_token)
      ident(jwt_token).applications
    end

    def application(jwt_token, app_id)
      ident(jwt_token).application(app_id)
    end

    def application_tokens(jwt_token, app_id)
      ident(jwt_token).application_tokens(app_id)
    end

    def authenticate(jwt_token, params)
      ident(jwt_token).authenticate(params)
    end

    def tokens(jwt_token)
      ident(jwt_token).tokens({})
    end

    def delete_token(jwt_token, token_id)
      ident(jwt_token).delete_token(token_id)
    end

    def create_user(jwt_token, params)
      ident(jwt_token).create_user(params)
    end

    def users(jwt_token)
      ident(jwt_token).users
    end
  end
end
