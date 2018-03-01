Rails.application.config.twilio_account_sid = ENV['TWILIO_ACCOUNT_SID'] || ''
Rails.application.config.twilio_auth_token = ENV['TWILIO_AUTH_TOKEN'] || ''
Rails.application.config.twilio_number = ENV['TWILIO_NUMBER'] || ''

Rails.application.config.twilio_client = Twilio::REST::Client.new(Rails.application.config.twilio_account_sid,
                                                                  Rails.application.config.twilio_auth_token)
