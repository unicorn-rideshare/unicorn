require 'stripe_mock'

RSpec.configure do |config|
  config.before { StripeMock.start }
  config.after  { StripeMock.stop }
end
