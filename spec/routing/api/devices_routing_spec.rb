require 'rails_helper'

describe Api::DevicesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/devices')).to(
          route_to('api/devices#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/devices/1')).to(
          route_to('api/devices#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/devices')).to(
          route_to('api/devices#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/devices/1')).to(
          route_to('api/devices#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/devices/1')).to(
          route_to('api/devices#destroy', id: '1', format: 'json'))
    end
  end
end
