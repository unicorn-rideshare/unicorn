require 'rails_helper'

describe 'api/providers/show' do
  let(:contact_attributes) do
    {
      name: 'Joe User',
      address1: 'addr1',
      address2: nil,
      city: 'ATL',
      state: 'GA',
      zip: '30328',
      email: 'u@ex.org',
      phone: 'p#',
      fax: 'f#',
      time_zone_id: 'Eastern Time (US & Canada)',
      mobile: 'm#',
      dob: nil
    }
  end
  let(:provider) { FactoryGirl.create(:provider, :with_user, contact_attributes: contact_attributes) }

  it 'should render provider' do
    @provider = provider
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => provider.id,
      'user_id' => provider.user.id,
      'profile_image_url' => provider.user.profile_image_url,
      'category_ids' => [],
      'contact' => {
        'id' => provider.contact.id,
        'name' => 'Joe User',
        'address1' => 'addr1',
        'address2' => nil,
        'city' => 'ATL',
        'state' => 'GA',
        'zip' => '30328',
        'email' => 'u@ex.org',
        'phone' => 'p#',
        'fax' => 'f#',
        'time_zone_id' => 'Eastern Time (US & Canada)',
        'latitude' => nil,
        'longitude' => nil,
        'mobile' => 'm#',
        'dob' => nil,
        'website' => nil,
        'description' => nil,
        'data' => nil,
      },
      'available' => false,
      'last_checkin_at' => nil,
      'last_checkin_latitude' => nil,
      'last_checkin_longitude' => nil,
      'last_checkin_heading' => nil,
    )
  end

  context 'when there is a recent checkin for the provider' do
    let(:checkin_at) { 3.minutes.ago }
    let(:checkin) { FactoryGirl.create(:checkin,
                                       locatable: provider.user,
                                       reason: 'just because',
                                       latitude: 90.0,
                                       longitude: -88.0,
                                       heading: 12.0,
                                       checkin_at: checkin_at) }

    before { checkin }

    it 'should render the last_checkin for the provider' do
      @provider = provider.reload
      render
      parsed = JSON.parse(rendered)
      expect(parsed['last_checkin_at']).to eq(checkin_at.iso8601)
      expect(parsed['last_checkin_latitude']).to eq(90.0)
      expect(parsed['last_checkin_longitude']).to eq(-88.0)
      expect(parsed['last_checkin_heading']).to eq(12.0)
    end
  end
end
