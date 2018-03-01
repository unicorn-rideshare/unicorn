class AngularPage < Page
  def current_page?
    with_retry do
      uri = URI.parse(page.current_url)
      uri.path == app_path && uri.fragment == angular_path
    end
  end

  def path
    app_path + '#' + angular_path
  end

  private

  def app_path
    '/'
  end

  def angular_path
    raise NotImplementedError, 'page object must define angular_path'
  end
end
