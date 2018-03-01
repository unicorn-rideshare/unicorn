class UrlShortenerService
  class << self
    def shorten(url)
      short_url = Shortener::ShortenedUrl.generate(url)
      "#{Rails.application.config.url_shortener_base_url}/#{short_url.unique_key}" if short_url.unique_key
    end
  end
end
