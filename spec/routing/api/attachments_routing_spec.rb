require 'rails_helper'

describe Api::AttachmentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/attachments')).to_not(be_routable)
    end

    it 'routes to #new' do
      expect(get('/api/attachments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/attachments/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/attachments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/attachments')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/attachments/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/attachments/1')).to_not(be_routable)
    end
  end
end
