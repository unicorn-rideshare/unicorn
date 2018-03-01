require 'rails_helper'

describe 'api/contacts/index' do
  it 'should render a list of contacts' do
    @contacts = FactoryGirl.create_list(:contact, 3)
    json = JSON.parse(render template: 'api/contacts/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
