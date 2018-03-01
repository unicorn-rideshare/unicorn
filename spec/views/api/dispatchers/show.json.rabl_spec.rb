require 'rails_helper'

describe 'api/dispatchers/show' do
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
      mobile: 'm#'
    }
  end
  let(:dispatcher) { FactoryGirl.create(:dispatcher, :with_user, contact_attributes: contact_attributes) }

  it 'should render dispatcher' do
    @dispatcher = dispatcher
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => dispatcher.id,
      'user_id' => dispatcher.user.id,
      'profile_image_url' => dispatcher.user.profile_image_url,
      'contact' => {
        'id' => dispatcher.contact.id,
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
        'data' => nil,
        'description' => nil,
      }
    )
  end
end
