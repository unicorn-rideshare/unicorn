require 'rails_helper'

describe 'api/devices/index' do
  it 'should render a list of devices' do
    @devices = FactoryGirl.create_list(:device, 3)
    json = JSON.parse(render template: 'api/devices/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
