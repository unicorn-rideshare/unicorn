require 'rails_helper'

describe Api::CompaniesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/companies')).to(
        route_to('api/companies#index', format: 'json'))
    end

    it 'routes to #new' do
      expect(get('/api/companies/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/companies/1')).to(
        route_to('api/companies#show', id: '1', format: 'json'))
    end

    it 'routes to #edit' do
      expect(get('/api/companies/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/companies')).to(
        route_to('api/companies#create', format: 'json'))
    end

    it 'routes to #update' do
      expect(put('/api/companies/1')).to(
        route_to('api/companies#update', id: '1', format: 'json'))
    end

    it 'routes to #destroy' do
      expect(delete('/api/companies/1')).to(
        route_to('api/companies#destroy', id: '1', format: 'json'))
    end
  end
end
