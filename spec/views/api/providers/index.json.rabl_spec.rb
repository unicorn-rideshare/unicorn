require 'rails_helper'

describe 'api/providers/index' do
  it 'should render a list of providers' do
    @providers = FactoryGirl.create_list(:provider, 3)
    json = JSON.parse(render template: 'api/providers/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
