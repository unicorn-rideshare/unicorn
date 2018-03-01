require 'rails_helper'

describe Api::CategoriesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/categories')).to(
          route_to('api/categories#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/categories/1')).to(
          route_to('api/categories#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/categories')).to(
          route_to('api/categories#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/categories/1')).to(
          route_to('api/categories#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/categories/1')).to(
          route_to('api/categories#destroy', id: '1', format: 'json'))
    end
  end
end
