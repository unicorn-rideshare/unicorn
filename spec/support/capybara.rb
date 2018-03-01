require 'capybara/webkit'
require 'phantomjs/poltergeist'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :safari do |app|
  Capybara::Selenium::Driver.new(app, browser: :safari)
end

BROWSER_DRIVER_MAP = {
    # browser     # driver
    nojs:         :rack_test,
    firefox:      :selenium,
    chrome:       :chrome,
    safari:       :safari,
    phantomjs:    :poltergeist,
    webkit:       :webkit,
    webkit_debug: :webkit_debug
}

def unsupported_browser(name)
  raise NotImplementedError, "#{name} is not a supported browser at this time. Options are: #{BROWSER_DRIVER_MAP.keys.join(', ')}"
end

def pick_browser(name)
  browser = BROWSER_DRIVER_MAP[name.to_sym]
  unsupported_browser(name) unless browser
  browser
end

Capybara.default_driver = pick_browser(ENV['BROWSER'] || :chrome)

RSpec.configure do |config|
  unless ENV['BROWSER'] # user preference wins over metadata
    # enable browser specification via metadata
    config.before(:example, type: :feature) do |example|
      browser = example.metadata[:browser]
      Capybara.current_driver = pick_browser(browser) if browser
    end
  end

  # ensure localStorage and sessionStorage are wiped after each feature
  config.before(:example, type: :feature) do
    unless Capybara.current_driver == :rack_test
      session = Capybara.current_session
      session.visit '/blank.html'
      session.evaluate_script('localStorage && localStorage.clear()')
      session.evaluate_script('sessionStorage && sessionStorage.clear()')
      session.reset! # return session to pristine state, like we found it
    end
  end
end
