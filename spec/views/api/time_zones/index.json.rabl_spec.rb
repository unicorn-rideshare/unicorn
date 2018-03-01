require 'rails_helper'

describe 'api/time_zones/index' do
  it 'should render a list of time zones' do
    @time_zones = TimeZone.all
    json = JSON.parse(render template: 'api/time_zones/index', formats: ['json'])
    expect(json.count).to eq(TimeZone.all.count)
  end
end
