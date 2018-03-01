require 'rails_helper'

describe Api::MarketsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/markets')).to(
          route_to('api/markets#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/markets/1')).to(
          route_to('api/markets#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/markets')).to(
          route_to('api/markets#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/markets/1')).to(
          route_to('api/markets#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/markets/1')).to(
          route_to('api/markets#destroy', id: '1', format: 'json'))
    end
  end
end
