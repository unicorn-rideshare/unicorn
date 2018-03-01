require 'rails_helper'

describe 'api/route_legs/index' do
  it 'should render a list of route legs' do
    @route_legs = FactoryGirl.create_list(:route_leg, 3)
    json = JSON.parse(render template: 'api/route_legs/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
