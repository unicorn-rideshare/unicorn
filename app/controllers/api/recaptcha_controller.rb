module Api
  class RecaptchaController < Api::ApplicationController
    include Recaptcha::Verify

    skip_before_action :authenticate_token!

    def create
      raise UnprocessableEntity unless recaptcha_response
      raise BadRequest unless recaptcha_response_verified?
      head :no_content
    end

    private

    def recaptcha_response
      params[:recaptcha_response]
    end

    def recaptcha_response_verified?
      verify_recaptcha response: recaptcha_response
    end
  end
end
