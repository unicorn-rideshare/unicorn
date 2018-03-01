require 'rails_helper'

describe 'url shortener' do
  describe 'routing' do
    it 'routes to #show' do
      expect(get('/m/abcde')).to(
          route_to('shortener/shortened_urls#show', id: 'abcde'))
    end
  end
end
