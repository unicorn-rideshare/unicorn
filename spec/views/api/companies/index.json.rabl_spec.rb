require 'rails_helper'

describe 'api/companies/index' do
  it 'should render a list of companies' do
    @companies = FactoryGirl.create_list(:company, 3)
    json = JSON.parse(render template: 'api/companies/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
