RSpec.configure do |config|
  config.before(:each, api: true) do
    return unless respond_to?(:request)
    request.env['HTTP_ACCEPT'] = 'application/json'
  end
end
