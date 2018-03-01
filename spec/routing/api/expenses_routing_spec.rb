require 'rails_helper'

describe Api::ExpensesController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get('/api/expenses')).to_not(be_routable)
    end

    it 'routes to #new' do
      expect(get('/api/expenses/new')).to_not(be_routable)
    end

    it 'routes to #show' do
      expect(get('/api/expenses/1')).to_not(be_routable)
    end

    it 'routes to #edit' do
      expect(get('/api/expenses/1/edit')).to_not(be_routable)
    end

    it 'routes to #create' do
      expect(post('/api/expenses')).to_not(be_routable)
    end

    it 'routes to #update' do
      expect(put('/api/expenses/1')).to_not(be_routable)
    end

    it 'routes to #destroy' do
      expect(delete('/api/expenses/1')).to_not(be_routable)
    end
  end
end
