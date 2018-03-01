require 'rails_helper'

describe Api::NotificationsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/notifications')).to(
          route_to('api/notifications#index', format: 'json'))
    end

    it 'does not route to #show' do
      expect(get('/api/notifications/1')).to_not be_routable
    end

    it 'does not route to #create' do
      expect(post('/api/notifications')).to_not be_routable
    end

    it 'does not route to #update' do
      expect(put('/api/notifications/1')).to_not be_routable
    end

    it 'does not route to #destroy' do
      expect(delete('/api/notifications/1')).to_not be_routable
    end
  end
end
