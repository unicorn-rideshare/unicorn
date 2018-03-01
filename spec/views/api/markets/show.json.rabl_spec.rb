require 'rails_helper'

describe 'api/markets/show' do
  let(:market) { FactoryGirl.create(:market, name: 'A Nickname for the Market') }

  it 'should render market' do
    @market = market
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => market.id,
                                        'name' => 'A Nickname for the Market',
                                        'google_place_id' => nil,
                                        'time_zone_id' => nil,
                                    )
  end
end
