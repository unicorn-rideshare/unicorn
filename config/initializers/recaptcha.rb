recaptcha_site_key = ENV['RECAPTCHA_SITE_KEY']
recaptcha_secret_key = ENV['RECAPTCHA_SECRET_KEY']

Recaptcha.configure do |config|
  config.public_key = recaptcha_site_key
  config.private_key = recaptcha_secret_key
end if recaptcha_site_key && recaptcha_secret_key

Rails.application.config.recaptcha_site_key = recaptcha_site_key
Rails.application.config.recaptcha_secret_key = recaptcha_secret_key
