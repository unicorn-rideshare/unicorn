if Rails.env.development? || Rails.env.production?
  Rails.application.config.gcm_client =  GCM.new(ENV['GCM_API_KEY']) if ENV['GCM_API_KEY']
end
