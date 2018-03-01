require 'rails_helper'

describe 'api/work_orders/index' do
  it 'should render a list of work orders' do
    @work_orders = FactoryGirl.create_list(:work_order, 3)
    json = JSON.parse(render template: 'api/work_orders/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
