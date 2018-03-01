require 'rails_helper'

describe 'api/users/index' do
  it 'should render a list of users' do
    @users = FactoryGirl.create_list(:user, 3)
    json = JSON.parse(render template: 'api/users/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
