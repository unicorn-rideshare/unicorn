require 'rails_helper'

describe 'api/checkins/index' do
  it 'should render a list of checkins' do
    @checkins = FactoryGirl.create_list(:checkin, 3)
    json = JSON.parse(render template: 'api/checkins/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
