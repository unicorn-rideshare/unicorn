require 'rails_helper'

describe 'api/dispatchers/index' do
  it 'should render a list of dispatchers' do
    @dispatchers = FactoryGirl.create_list(:dispatcher, 3)
    json = JSON.parse(render template: 'api/dispatchers/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
