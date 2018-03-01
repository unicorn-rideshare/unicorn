require 'rails_helper'

describe Api::WorkOrdersController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/work_orders')).to(
          route_to('api/work_orders#index', format: 'json'))
    end

    it 'routes to #show' do
      expect(get('/api/work_orders/1')).to(
          route_to('api/work_orders#show', id: '1', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/work_orders')).to(
          route_to('api/work_orders#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/work_orders/1')).to(
          route_to('api/work_orders#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/work_orders/1')).to(
          route_to('api/work_orders#destroy', id: '1', format: 'json'))
    end

    it 'routes to #call' do
      expect(post('/api/work_orders/1/call')).to(
          route_to('api/work_orders#call', id: '1', format: 'xml'))
    end
  end
end
