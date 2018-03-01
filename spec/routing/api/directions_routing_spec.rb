require 'rails_helper'

describe Api::DirectionsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/directions')).to(
          route_to('api/directions#index', format: 'json'))
    end

    it 'routes to #eta' do
      expect(get('/api/directions/eta')).to(
          route_to('api/directions#eta', format: 'json'))
    end
  end
end
