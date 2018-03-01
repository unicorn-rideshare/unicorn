require 'rails_helper'

describe 'api/markets/index' do
  it 'should render a list of markets' do
    @markets = FactoryGirl.create_list(:market, 3)
    json = JSON.parse(render template: 'api/markets/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
