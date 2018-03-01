require 'rails_helper'

describe Api::TasksController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/tasks')).to(
          route_to('api/tasks#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/tasks/1')).to(
          route_to('api/tasks#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/tasks')).to(
          route_to('api/tasks#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/tasks/1')).to(
          route_to('api/tasks#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/tasks/1')).to(
          route_to('api/tasks#destroy', id: '1', format: 'json'))
    end
  end
end
