module Api
  class TokensController < Api::ApplicationController
    load_and_authorize_resource except: :create
    skip_before_action :authenticate_token!, only: :create

    def create
      user = User.authenticate_fb_access_token(params[:fb_access_token]) if params[:fb_access_token]
      user = User.authenticate(params[:email], params[:password]) if user.nil? && params[:email] && params[:password]
      if user
        @token = user.tokens.create
        respond_with(:api, @token, template: 'api/tokens/show', status: :created)
      else
        head :unauthorized
      end
    end

    def destroy
      @token.destroy
      respond_with(:api, @token)
    end
  end
end
