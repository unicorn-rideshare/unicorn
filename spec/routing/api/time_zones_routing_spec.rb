require 'rails_helper'

describe Api::TimeZonesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/time_zones')).to(
        route_to('api/time_zones#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/time_zones/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/time_zones/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/time_zones/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/time_zones')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/time_zones/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/time_zones/1')).to_not(be_routable)
    end
  end
end
