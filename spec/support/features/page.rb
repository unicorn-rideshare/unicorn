class Page
  class << self
    def input_accessor(*names, type: 'text')
      names.each do |name|
        define_method("#{name}=") do |value|
          page.fill_in name, with: value
        end

        define_method("has_#{name}?") do |value|
          page.has_field? name, type: type.to_s, with: value
        end
      end
    end

    def select_accessor(*names)
      names.each do |name|
        define_method("#{name}=") do |value|
          page.select value, from: name
        end

        define_method("has_#{name}?") do |value|
          page.has_select?(name, selected: value)
        end
      end
    end
  end

  def initialize(*); end

  def account_menu
    UI::AccountMenu.new(page)
  end

  def current_page?
    with_retry do
      uri = URI.parse(page.current_url)
      uri.path == path
    end
  end

  def has_flash_message?(type, message)
    page.has_selector?(".alert.alert-#{type}", text: message)
  end

  def has_modal?
    page.has_selector? '.modal-dialog'
  end

  def has_no_modal?
    page.has_no_selector? '.modal-dialog'
  end

  def path
    raise NotImplementedError, 'page object must define path'
  end

  def populate_form_with(user_data)
    # TODO: Deprecated; use getter/modifer DSL
    user_data.each do |field, value|
      # supports finding fields either by id or name attributes
      input = page.find("##{field}, [name='#{field}']")
      if input.tag_name == 'select'
        input.select value
      else
        input.set value
      end
    end
  end

  def visit
    page.visit path
    self
  end

  private

  def block_until_location_changes
    current_location = path
    return_val = yield if block_given?
    block_until { current_location != path }
    return_val
  end

  def page
    # TODO: Include Capybara::DSL and assert self.current_page?
    Capybara.current_session
  end

  # Akin to Capybara's old #wait_until method. Use this when the condition you are
  # asserting cannot be automatically retried by a Capybara matcher or finder,
  # e.g., waiting for the URL to change
  def with_retry(interval: 0.1, max_time: Capybara.default_wait_time)
    passing = false
    attempts_remaining = max_time / interval
    while !passing && attempts_remaining > 0
      passing = yield
      break if passing
      attempts_remaining -= 1
      sleep interval
    end
    passing
  end

  alias_method :block_until, :with_retry
end
