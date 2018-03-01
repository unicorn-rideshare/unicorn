require 'rails_helper'

describe 'api/routes/index' do
  it 'should render a list of routes' do
    @routes_collection = FactoryGirl.create_list(:route, 3) # @routes does not work in test env
    json = JSON.parse(render template: 'api/routes/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
