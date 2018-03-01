DatabaseCleaner[:active_record].strategy = :transaction
DatabaseCleaner[:redis].strategy = :truncation
DatabaseCleaner[:redis].db = Settings.redis.url

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: %w(spatial_ref_sys))
    Rails.application.load_seed
  end

  config.before(:each) do |example|
    # Feature specs require :truncation in order to support the web server and test suite running in different threads
    active_record_strategy = example.metadata[:type] == :feature ? :truncation : :transaction
    options = active_record_strategy == :truncation ? { except: %w(spatial_ref_sys) } : {}
    DatabaseCleaner[:active_record].strategy = active_record_strategy, options
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
