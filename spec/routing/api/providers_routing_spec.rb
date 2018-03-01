require 'rails_helper'

describe Api::ProvidersController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/providers')).to(
        route_to('api/providers#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/providers/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/providers/1')).to(
        route_to('api/providers#show', id: '1', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/providers/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/providers')).to(
        route_to('api/providers#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/providers/1')).to(
        route_to('api/providers#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/providers/1')).to(
        route_to('api/providers#destroy', id: '1', format: 'json'))
    end

    it 'routes to #availability' do
      expect(get('/api/providers/availability')).to(
          route_to('api/providers#availability', format: 'json'))
    end
  end
end
