class TwilioService

  class << self
    def send_sms(recipients, body)
      recipients.each do |recipient|
        twilio_client.account.messages.create(
            from: Rails.application.config.twilio_number,
            to: recipient,
            body: body
        )
      end
    end

    def verify_signature(request)
      auth_token = Rails.application.config.twilio_auth_token
      validator = Twilio::Util::RequestValidator.new(auth_token)

      method = request.method.downcase.to_sym
      url = request.original_url

      env = request.env
      params = method == :get ? env['rack.request.query_hash'] : env['rack.request.form_hash']
      signature = request.headers['x-twilio-signature']

      validator.validate(url, params, signature)
    end

    private

    def twilio_client
      Rails.application.config.twilio_client
    end
  end
end
