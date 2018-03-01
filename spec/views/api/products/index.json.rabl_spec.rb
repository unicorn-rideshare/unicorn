require 'rails_helper'

describe 'api/products/index' do
  it 'should render a list of products' do
    @products = FactoryGirl.create_list(:product, 3)
    json = JSON.parse(render template: 'api/products/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
