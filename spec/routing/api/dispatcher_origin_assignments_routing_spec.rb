require 'rails_helper'

describe Api::DispatcherOriginAssignmentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/markets/1/origins/2/dispatcher_origin_assignments')).to(
          route_to('api/dispatcher_origin_assignments#index', market_id: '1', origin_id: '2', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/markets/1/origins/2/dispatcher_origin_assignments/3')).to(
          route_to('api/dispatcher_origin_assignments#show', market_id: '1', origin_id: '2', id: '3', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/markets/1/origins/2/dispatcher_origin_assignments')).to(
          route_to('api/dispatcher_origin_assignments#create', market_id: '1', origin_id: '2', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/markets/1/origins/2/dispatcher_origin_assignments/3')).to(
          route_to('api/dispatcher_origin_assignments#update', market_id: '1', origin_id: '2', id: '3', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/markets/1/origins/2/dispatcher_origin_assignments/3')).to(
          route_to('api/dispatcher_origin_assignments#destroy', market_id: '1', origin_id: '2', id: '3', format: 'json'))
    end
  end
end
