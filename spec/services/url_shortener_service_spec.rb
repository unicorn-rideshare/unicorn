require 'rails_helper'

describe UrlShortenerService do
  describe '#shorten' do
    context 'when the given url is shortened successfully' do
      let(:long_url)      { 'http://example.com/the/uri' }
      let(:expected_url)  { "http://localhost:3000/m/#{Shortener::ShortenedUrl.first.unique_key}" }

      it 'should return the shortened url' do
        expect(UrlShortenerService.shorten('http://example.com/the/uri')).to eq(expected_url)
      end
    end

    context 'when the given url is not shortened successfully' do
      it 'should return nil' do
        expect(UrlShortenerService.shorten('')).to be_nil
      end
    end
  end
end
