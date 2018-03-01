require 'rails_helper'

describe 'api/origins/index' do
  it 'should render a list of origins' do
    @origins = FactoryGirl.create_list(:origin, 3)
    json = JSON.parse(render template: 'api/origins/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
