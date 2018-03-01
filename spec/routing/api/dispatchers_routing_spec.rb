require 'rails_helper'

describe Api::DispatchersController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/dispatchers')).to(
        route_to('api/dispatchers#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/dispatchers/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/dispatchers/1')).to(
        route_to('api/dispatchers#show', id: '1', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/dispatchers/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/dispatchers')).to(
        route_to('api/dispatchers#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/dispatchers/1')).to(
        route_to('api/dispatchers#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/dispatchers/1')).to(
        route_to('api/dispatchers#destroy', id: '1', format: 'json'))
    end
  end
end
