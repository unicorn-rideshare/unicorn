require 'rails_helper'

describe Api::RoutesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/routes')).to(
          route_to('api/routes#index', format: 'json'))
    end

    it 'routes to #index' do
      expect(get('/api/markets/1/origins/2/provider_origin_assignments/3/routes')).to(
          route_to('api/routes#index', market_id: '1', origin_id: '2', provider_origin_assignment_id: '3', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/routes/1')).to(
          route_to('api/routes#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/routes')).to(
          route_to('api/routes#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/routes/1')).to(
          route_to('api/routes#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/routes/1')).to(
          route_to('api/routes#destroy', id: '1', format: 'json'))
    end
  end
end
