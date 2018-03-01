require 'rails_helper'

describe 'api/route_legs/show' do
  let(:actual_start_at)           { DateTime.parse('2015-02-08T19:00:00Z') }
  let(:actual_end_at)             { actual_start_at + 45.minutes }
  let(:actual_traffic)            { 2 }
  let(:estimated_start_at)        { actual_start_at - 10.minutes }
  let(:estimated_end_at)          { actual_end_at + 12.minutes }
  let(:estimated_end_at_on_start) { actual_end_at + 1.minute }
  let(:estimated_traffic)         { 1 }

  let(:work_order)  { FactoryGirl.create(:work_order) }

  let(:route_leg) { FactoryGirl.create(:route_leg,
                                       actual_start_at: actual_start_at,
                                       actual_end_at: actual_end_at,
                                       actual_traffic: actual_traffic,
                                       estimated_start_at: estimated_start_at,
                                       estimated_end_at: estimated_end_at,
                                       estimated_end_at_on_start: estimated_end_at_on_start,
                                       estimated_traffic: estimated_traffic,
                                       work_order: work_order) }

  it 'should render route leg' do
    @route_leg = route_leg
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => route_leg.id,
                                        'actual_start_at' => '2015-02-08T19:00:00Z',
                                        'actual_end_at' => '2015-02-08T19:45:00Z',
                                        'actual_traffic' => 2.0,
                                        'estimated_start_at' => '2015-02-08T18:50:00Z',
                                        'estimated_end_at' => '2015-02-08T19:57:00Z',
                                        'estimated_end_at_on_start' => '2015-02-08T19:46:00Z',
                                        'estimated_traffic' => 1.0,
                                        'work_order_id' => work_order.id
                                    )
  end
end
