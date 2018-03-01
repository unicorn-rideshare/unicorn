class AnyPage < Page
  class << self
    delegate :visit, to: :new
  end

  def current_page?
    true
  end

  def path
    '/'
  end
end
