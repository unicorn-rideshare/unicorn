module Unicorn
  class Scraper

    attr_reader :base_url

    def initialize(base_url)
      @base_url = base_url
    end

    def fetch(uri, query_params = {})
      response = Typhoeus::Request.get("#{base_url}#{uri}?#{URI.encode_www_form(query_params)}",
                                       headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36' })
      if response.code == 200 || response.code == 304
        Nokogiri::HTML(response.body)
      end
    end
  end
end
