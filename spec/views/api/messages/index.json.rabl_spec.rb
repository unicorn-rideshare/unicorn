require 'rails_helper'

describe 'api/messages/index' do
  it 'should render a list of messages' do
    @messages = FactoryGirl.create_list(:message, 3)
    json = JSON.parse(render template: 'api/messages/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
