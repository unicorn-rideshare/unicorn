if Rails.env.test?
  Rails.application.config.default_mailer_from_address = 'mailer@example.com'
  ActionMailer::Base.delivery_method = :test
else
  Rails.application.config.default_mailer_from_address = ENV['SMTP_USERNAME']

  if ENV['SMTP_HOST'] && ENV['SMTP_USERNAME'] && ENV['SMTP_PASSWORD']
    ActionMailer::Base.smtp_settings = {
        address: ENV['SMTP_HOST'],
        port: ENV['SMTP_PORT'] ? ENV['SMTP_PORT'].to_i : 587,
        enable_starttls_auto: true,
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'login'
    }
  end

  ActionMailer::Base.delivery_method = :smtp
end
