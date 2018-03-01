require 'rails_helper'

describe 'api/customers/index' do
  it 'should render a list of customers' do
    @customers = FactoryGirl.create_list(:customer, 3)
    json = JSON.parse(render template: 'api/customers/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
