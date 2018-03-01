require 'rails_helper'

describe 'api/categories/index' do
  it 'should render a list of categories' do
    @categories = FactoryGirl.create_list(:category, 3)
    json = JSON.parse(render template: 'api/categories/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
