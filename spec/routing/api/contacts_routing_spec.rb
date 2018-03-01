require 'rails_helper'

describe Api::ContactsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/contacts')).to(
        route_to('api/contacts#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/contacts/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/contacts/1')).to(
        route_to('api/contacts#show', id: '1', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/contacts/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/contacts')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/contacts/1')).to(
        route_to('api/contacts#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/contacts/1')).to_not(be_routable)
    end
  end
end
