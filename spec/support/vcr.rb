require 'vcr'

VCR.configure do |config|
  config.configure_rspec_metadata!

  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock
end
