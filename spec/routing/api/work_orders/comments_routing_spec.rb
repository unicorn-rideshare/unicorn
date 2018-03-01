require 'rails_helper'

describe Api::CommentsController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/work_orders/2/comments')).to(
        route_to('api/comments#index', format: 'json', work_order_id: '2'))
    end

    it 'routes to #new' do
      expect(get('/api/work_orders/2/comments/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/work_orders/2/comments/1')).to(
          route_to('api/comments#show', format: 'json', work_order_id: '2', id: '1'))
    end

    it 'routes to #edit' do
      expect(get('/api/work_orders/2/comments/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/work_orders/2/comments')).to(
        route_to('api/comments#create', format: 'json', work_order_id: '2'))
    end

    it 'routes to #update' do
      expect(put('/api/work_orders/2/comments/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/work_orders/2/comments/1')).to_not(be_routable)
    end

    describe 'attachments' do
      it 'routes to #index' do
        expect(get('/api/work_orders/2/comments/1/attachments')).to(
            route_to('api/attachments#index', format: 'json', work_order_id: '2', comment_id: '1'))
      end

      it 'routes to #new' do
        expect(get('/api/work_orders/2/comments/1/attachments/new')).to_not(be_routable)
      end

      it 'routes to #show' do
        expect(get('/api/work_orders/3/comments/2/attachments/1')).to(
            route_to('api/attachments#show', format: 'json', work_order_id: '3', comment_id: '2', id: '1'))
      end

      it 'routes to #edit' do
        expect(get('/api/work_orders/3/comments/2/attachments/1/edit')).to_not(be_routable)
      end

      it 'routes to #create' do
        expect(post('/api/work_orders/3/comments/2/attachments')).to(
            route_to('api/attachments#create', format: 'json', work_order_id: '3', comment_id: '2'))
      end

      it 'routes to #update' do
        expect(put('/api/work_orders/3/comments/2/attachments/1')).to(
            route_to('api/attachments#update', format: 'json', work_order_id: '3', comment_id: '2', id: '1'))
      end

      it 'routes to #destroy' do
        expect(delete('/api/work_orders/3/comments/2/attachments/1')).to(
            route_to('api/attachments#destroy', format: 'json', work_order_id: '3', comment_id: '2', id: '1'))
      end
    end
  end
end
