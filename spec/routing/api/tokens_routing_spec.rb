require 'rails_helper'

describe Api::TokensController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/tokens')).to_not(be_routable)
    end

    it 'routes to #new' do
      expect(get('/api/tokens/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/tokens/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/tokens/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/tokens')).to(
        route_to('api/tokens#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/tokens/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/tokens/1')).to(
        route_to('api/tokens#destroy', id: '1', format: 'json'))
    end
  end
end
