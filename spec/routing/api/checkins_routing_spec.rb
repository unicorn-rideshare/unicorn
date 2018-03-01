require 'rails_helper'

describe Api::CheckinsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/checkins')).to(
        route_to('api/checkins#index', format: 'json'))
    end

    it 'routes to #create' do
      expect(post('/api/checkins')).to(
        route_to('api/checkins#create', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/checkins/1')).to(
        route_to('api/checkins#destroy', id: '1', format: 'json'))
    end
  end
end
