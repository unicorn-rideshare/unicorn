require 'rails_helper'

describe WorkOrdersController do
  describe 'routing' do
    it 'does not route to #index' do
      expect(get('/work_orders')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/work_orders/1')).to(
        route_to('work_orders#show', id: '1'))
    end

    it 'does not route to #create' do
      expect(post('/work_orders')).to_not(be_routable)
    end

    it 'does not route to #update' do
      expect(put('/work_orders/1')).to_not(be_routable)
    end

    it 'does not route to #destroy' do
      expect(delete('/work_orders/1')).to_not(be_routable)
    end
  end
end
