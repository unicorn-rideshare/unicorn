require 'rails_helper'

describe Api::AttachmentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/users/2/attachments')).to(
          route_to('api/attachments#index', format: 'json', user_id: '2'))
    end

    it 'routes to #new' do
      expect(get('/api/users/2/attachments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/users/2/attachments/1')).to(
          route_to('api/attachments#show', format: 'json', user_id: '2', id: '1'))
    end

    it 'routes to #edit' do
      expect(get('/api/users/2/attachments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/users/2/attachments')).to(
          route_to('api/attachments#create', format: 'json', user_id: '2'))
    end

    it 'routes to #update' do
      expect(put('/api/users/2/attachments/1')).to(
          route_to('api/attachments#update', format: 'json', user_id: '2', id: '1'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/users/2/attachments/1')).to(
          route_to('api/attachments#destroy', format: 'json', user_id: '2', id: '1'))
    end
  end
end
