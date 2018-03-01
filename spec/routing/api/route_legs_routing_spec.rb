require 'rails_helper'

describe Api::RouteLegsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/routes/1/route_legs')).to(
          route_to('api/route_legs#index', route_id: '1', format: 'json'))
    end

    it 'does not route to #show' do
      expect(get('/api/routes/1/route_legs/2')).to_not(be_routable)
    end

    it 'does not route to #create' do
      expect(post('/api/routes/1/route_legs')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/routes/1/route_legs/2')).to(
          route_to('api/route_legs#update', route_id: '1', id: '2', format: 'json'))
    end

    it 'does not route to #destroy' do
      expect(delete('/api/routes/1/route_legs/2')).to_not(be_routable)
    end
  end
end
