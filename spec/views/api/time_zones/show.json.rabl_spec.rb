require 'rails_helper'

describe 'api/time_zones/show' do
  let(:time_zone) { TimeZone.find('Eastern Time (US & Canada)') }

  it 'should render time zone' do
    @time_zone = time_zone
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => 'Eastern Time (US & Canada)',
      'name' => 'Eastern Time (US & Canada)'
    )
  end
end
