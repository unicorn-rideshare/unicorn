require 'rails_helper'

describe 'api/provider_origin_assignments/index' do
  it 'should render a list of provider origin assignments' do
    @provider_origin_assignments = FactoryGirl.create_list(:provider_origin_assignment, 3, start_date: Date.today, end_date: Date.today)
    json = JSON.parse(render template: 'api/provider_origin_assignments/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
