require 'rails_helper'

describe 'api/expenses/index' do
  it 'should render a list of expenses' do
    @expenses = FactoryGirl.create_list(:expense, 3)
    json = JSON.parse(render template: 'api/expenses/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
