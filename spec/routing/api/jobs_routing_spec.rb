require 'rails_helper'

describe Api::JobsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/jobs')).to(
          route_to('api/jobs#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/jobs/1')).to(
          route_to('api/jobs#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/jobs')).to(
          route_to('api/jobs#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/jobs/1')).to(
          route_to('api/jobs#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/jobs/1')).to(
          route_to('api/jobs#destroy', id: '1', format: 'json'))
    end
  end
end
