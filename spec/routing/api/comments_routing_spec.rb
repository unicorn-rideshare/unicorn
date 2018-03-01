require 'rails_helper'

describe Api::CommentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/comments')).to_not(be_routable)
    end

    it 'routes to #new' do
      expect(get('/api/comments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/comments/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/comments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/comments')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/comments/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/comments/1')).to_not(be_routable)
    end
  end
end
