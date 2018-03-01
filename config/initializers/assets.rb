# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js.coffee.erb, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w(application.js provide.js login.css customer.css)

Rails.application.config.assets.precompile += %w(
  no-animations.css
  teaspoon.css
  jasmine/1.3.1.js
  teaspoon-jasmine.js
  teaspoon-teaspoon.js
) if Rails.env.test?

Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|woff2|ttf|otf)$/

BowerRails.configure do |bower_rails|
  # Tell bower-rails what path should be considered as root. Defaults to Dir.pwd
  # bower_rails.root_path = Dir.pwd

  # Invokes rake bower:install before precompilation. Defaults to false
  # bower_rails.install_before_precompile = true

  # Invokes rake bower:resolve before precompilation. Defaults to false
  # bower_rails.resolve_before_precompile = true

  # Invokes rake bower:clean before precompilation. Defaults to false
  # bower_rails.clean_before_precompile = true

  # Invokes rake bower:install:deployment instead rake bower:install. Defaults to false
  # bower_rails.use_bower_install_deployment = true
end

# include bower components
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')
