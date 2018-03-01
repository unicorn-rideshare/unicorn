require 'rails_helper'

describe Api::MessagesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/messages')).to(
          route_to('api/messages#index', format: 'json'))
    end

    it 'does not route to #show' do
      expect(get('/api/messages/1')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/messages')).to(
          route_to('api/messages#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/messages/1')).to(
          route_to('api/messages#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/messages/1')).to(
          route_to('api/messages#destroy', id: '1', format: 'json'))
    end

    it 'routes to #conversations' do
      expect(get('/api/messages/conversations')).to(
          route_to('api/messages#conversations', format: 'json'))
    end
  end
end
