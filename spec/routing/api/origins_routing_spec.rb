require 'rails_helper'

describe Api::OriginsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/markets/1/origins')).to(
          route_to('api/origins#index', market_id: '1', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/markets/1/origins/2')).to(
          route_to('api/origins#show', market_id: '1', id: '2', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/markets/1/origins')).to(
          route_to('api/origins#create', market_id: '1', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/markets/1/origins/2')).to(
          route_to('api/origins#update', market_id: '1', id: '2', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/markets/1/origins/2')).to(
          route_to('api/origins#destroy', market_id: '1', id: '2', format: 'json'))
    end
  end
end
