require 'rails_helper'

describe Api::InvitationsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/invitations')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/invitations/1')).to(
          route_to('api/invitations#show', id: '1', format: 'json'))

      expect(get('/api/invitations/0123')).to(
          route_to('api/invitations#show', id: '0123', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/invitations/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/invitations')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/invitations/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/invitations/1')).to_not(be_routable)
    end
  end
end
