require 'houston'

Rails.application.config.houston_clients = {}

certificate = ENV['APN_CERTIFICATE_RAW']
certificate = (File.read(Rails.root.join(".apn-#{Rails.env}.pem")) rescue nil) if certificate.nil?

if Rails.env.development? || Rails.env.test? || ENV['APN_ENV_DEVELOPMENT'].to_s.match(/^true$/i)
  Rails.application.config.default_houston_client = Houston::Client.development
  Rails.application.config.default_houston_client.certificate = certificate
elsif Rails.env.production?
  Rails.application.config.default_houston_client = Houston::Client.production
  Rails.application.config.default_houston_client.certificate = certificate

  Dir.glob(Rails.root.join('.apn', '*.pem')) do |apn_cert|
    bundle_id = File.basename(apn_cert, '.pem')
    houston_client = Houston::Client.production
    houston_client.certificate = File.read(apn_cert)
    Rails.application.config.houston_clients[bundle_id] = houston_client
  end
end
