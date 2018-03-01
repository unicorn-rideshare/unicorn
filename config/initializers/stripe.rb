if Rails.env.development? || Rails.env.test?
  Rails.application.config.stripe.secret_key = ENV['STRIPE_SECRET_KEY'] || ''
  Rails.application.config.stripe.publishable_key = ENV['STRIPE_PUBLISHABLE_KEY'] || ''
elsif Rails.env.production?
  Rails.application.config.stripe.secret_key = ENV['STRIPE_SECRET_KEY'] || ''
  Rails.application.config.stripe.publishable_key = ENV['STRIPE_PUBLISHABLE_KEY'] || ''
end
