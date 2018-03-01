module ControllerTestHelpers
  def sign_in(authenticable)
    token = FactoryGirl.build(:token, authenticable: authenticable)
    hashed_token = Base64.urlsafe_encode64("#{token.token}:token_uuid")
    header_name = %w(X-API-Authorization x-api-authorization).sample
    request.headers[header_name] = "Basic #{hashed_token}"
    allow(Token).to receive(:find_by_token).with(token.token).and_return(token)
    allow(token).to receive(:authenticate).with('token_uuid').and_return(true)
  end
end

module RequestTestHelpers
end

RSpec.configure do |config|
  config.include ControllerTestHelpers, type: :controller
  config.include RequestTestHelpers, type: :request
end
