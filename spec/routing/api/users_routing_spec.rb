require 'rails_helper'

describe Api::UsersController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/users')).to_not(be_routable)
    end

    it 'does not route to #new' do
      expect(get('/api/users/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/users/1')).to(
        route_to('api/users#show', id: '1', format: 'json'))
    end

    it 'does not route to #edit' do
      expect(get('/api/users/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/users')).to(
          route_to('api/users#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/users/1')).to(
        route_to('api/users#update', id: '1', format: 'json'))
    end

    it 'does not route to #destroy' do
      expect(delete('/api/users/1')).to_not(be_routable)
    end

    it 'routes to #reset_password' do
      expect(post('/api/users/reset_password')).to(
          route_to('api/users#reset_password', format: 'json'))
    end
  end
end
