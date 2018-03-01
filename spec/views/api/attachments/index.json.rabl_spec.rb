require 'rails_helper'

describe 'api/attachments/index' do
  it 'should render a list of attachments' do
    @attachments = FactoryGirl.create_list(:attachment, 3)
    json = JSON.parse(render template: 'api/attachments/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
