require 'rails_helper'

describe Api::CommentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/customers/2/comments')).to(
        route_to('api/comments#index', format: 'json', customer_id: '2'))
    end

    it 'routes to #new' do
      expect(get('/api/customers/2/comments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/customers/2/comments/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/customers/2/comments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/customers/2/comments')).to(
        route_to('api/comments#create', format: 'json', customer_id: '2'))
    end

    it 'routes to #update' do
      expect(put('/api/customers/2/comments/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/customers/2/comments/1')).to_not(be_routable)
    end
  end
end
