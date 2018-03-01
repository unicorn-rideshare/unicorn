require 'rails_helper'

describe 'api/notifications/index' do
  it 'should render a list of notifications' do
    @notifications = FactoryGirl.create_list(:notification, 3)
    json = JSON.parse(render template: 'api/notifications/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
