Koala.configure do |config|
  config.app_access_token = ENV['FACEBOOK_APP_ACCESS_TOKEN']
  config.app_id = ENV['FACEBOOK_APP_ID']
  config.app_secret = ENV['FACEBOOK_APP_SECRET']
end
