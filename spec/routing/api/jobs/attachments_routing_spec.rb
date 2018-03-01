require 'rails_helper'

describe Api::AttachmentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/jobs/2/attachments')).to(
        route_to('api/attachments#index', format: 'json', job_id: '2'))
    end

    it 'routes to #new' do
      expect(get('/api/jobs/2/attachments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/jobs/2/attachments/1')).to(
          route_to('api/attachments#show', format: 'json', job_id: '2', id: '1'))
    end

    it 'routes to #edit' do
      expect(get('/api/jobs/2/attachments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/jobs/2/attachments')).to(
        route_to('api/attachments#create', format: 'json', job_id: '2'))
    end

    it 'routes to #update' do
      expect(put('/api/jobs/2/attachments/1')).to(
          route_to('api/attachments#update', format: 'json', job_id: '2', id: '1'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/jobs/2/attachments/1')).to(
          route_to('api/attachments#destroy', format: 'json', job_id: '2', id: '1'))
    end

    describe 'comments' do
      it 'routes to #index' do
        expect(get('/api/jobs/2/attachments/1/comments')).to(
            route_to('api/comments#index', format: 'json', job_id: '2', attachment_id: '1'))
      end

      it 'routes to #create' do
        expect(post('/api/jobs/2/attachments/1/comments')).to(
            route_to('api/comments#create', format: 'json', job_id: '2', attachment_id: '1'))
      end

      it 'does not route to #update' do
        expect(put('/api/jobs/2/attachments/1/comments')).to_not(be_routable)
      end

      it 'does not route to #destroy' do
        expect(delete('/api/jobs/2/attachments/1/comments')).to_not(be_routable)
      end
    end
  end
end
