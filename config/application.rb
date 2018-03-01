require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Unicorn
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths += %W(#{config.root}/lib
                                #{config.root}/app/jobs/attachments
                                #{config.root}/app/jobs/companies
                                #{config.root}/app/jobs/contacts
                                #{config.root}/app/jobs/devices
                                #{config.root}/app/jobs/invitations
                                #{config.root}/app/jobs/markets
                                #{config.root}/app/jobs/messages
                                #{config.root}/app/jobs/notifications
                                #{config.root}/app/jobs/providers
                                #{config.root}/app/jobs/routes
                                #{config.root}/app/jobs/tasks
                                #{config.root}/app/jobs/stripe
                                #{config.root}/app/jobs/tokens
                                #{config.root}/app/jobs/users
                                #{config.root}/app/jobs/work_orders
                                #{config.root}/app/models/concerns/abilities
                                #{config.root}/app/models/concerns/settings)

    config.generators do |generators|
      generators.view_specs false
      generators.helper_specs false
      generators.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    require_relative './settings'
    default_mail_uri = URI.parse(Settings.app.url)
    default_mail_host = default_mail_uri.host
    default_mail_host += ":#{default_mail_uri.port}" unless [80, 443].include?(default_mail_uri.port)
    config.action_mailer.default_url_options = { host: default_mail_host }

    config.assets.enabled = true

    Rabl.configure do |config|
      config.view_paths << Rails.root.join('app/views/api')
    end

    # CORS
    uri = URI.parse(ENV['APP_URL'] || 'http://localhost:3000')
    cors_origins = ENV['CORS_ORIGINS'].split(/ /) rescue nil
    origin = cors_origins || (Rails.env.development? ? '*' : "#{uri.scheme}://*.#{uri.to_s.gsub(/^.*:\/\//i, '')}")
    config.middleware.insert_before 0, Rack::Cors.name do
      allow do
        origins origin
        resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
      end
    end
  end
end
