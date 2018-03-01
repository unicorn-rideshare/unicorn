require 'rails_helper'

describe 'api/checkins/show' do
  let(:user)  { FactoryGirl.create(:user) }
  let(:checkin_at) { 10.days.ago }
  let(:checkin) { FactoryGirl.create(:checkin,
                                     locatable: user,
                                     reason: 'just because',
                                     latitude: 90.0,
                                     longitude: -88.0,
                                     checkin_at: checkin_at) }

  it 'should render checkin' do
    @checkin = checkin
    render
    expect(JSON.parse(rendered)).to eq(
                                        'locatable_id' => user.id,
                                        'locatable_type' => 'user',
                                        'reason' => 'just because',
                                        'latitude' => 90.0,
                                        'longitude' => -88.0,
                                        'heading' => 0.0,
                                        'checkin_at' => checkin_at.iso8601
                                    )
  end
end
