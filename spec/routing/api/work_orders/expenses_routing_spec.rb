require 'rails_helper'

describe Api::ExpensesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/work_orders/2/expenses')).to(
          route_to('api/expenses#index', format: 'json', work_order_id: '2'))
    end

    it 'does not route to #new' do
      expect(get('/api/work_orders/2/expenses/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/work_orders/2/expenses/1')).to_not(be_routable)
    end

    it 'does not route to #edit' do
      expect(get('/api/work_orders/2/expenses/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/work_orders/2/expenses')).to(
          route_to('api/expenses#create', format: 'json', work_order_id: '2'))
    end

    it 'routes to #update' do
      expect(put('/api/work_orders/2/expenses/1')).to(
          route_to('api/expenses#update', format: 'json', work_order_id: '2', id: '1'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/work_orders/2/expenses/1')).to(
          route_to('api/expenses#destroy', format: 'json', work_order_id: '2', id: '1'))
    end
  end
end
