require 'rails_helper'

describe Api::ProductsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/products')).to(
          route_to('api/products#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/products/2')).to(
          route_to('api/products#show', id: '2', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/products')).to(
          route_to('api/products#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/products/2')).to(
          route_to('api/products#update', id: '2', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/products/2')).to(
          route_to('api/products#destroy', id: '2', format: 'json'))
    end
  end
end
