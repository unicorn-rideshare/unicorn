require 'rails_helper'

describe Api::UserOrderSharesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/user_order_shares')).to(
          route_to('api/user_order_shares#index', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/user_order_shares')).to(
          route_to('api/user_order_shares#create', format: 'json'))
    end
  end
end
