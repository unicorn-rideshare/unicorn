require 'rails_helper'

describe Api::CustomersController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/customers')).to(
        route_to('api/customers#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/customers/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/customers/1')).to(
        route_to('api/customers#show', id: '1', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/customers/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/customers')).to(
        route_to('api/customers#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/customers/1')).to(
        route_to('api/customers#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/customers/1')).to(
        route_to('api/customers#destroy', id: '1', format: 'json'))
    end
  end
end
