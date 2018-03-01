require 'rails_helper'

describe 'api/customers/show' do
  let(:contact_attributes) do
    {
      name: 'Joe Customer',
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
  let(:customer) { FactoryGirl.create(:customer,
                                      contact_attributes: contact_attributes,
                                      name: 'Joe Customer',
                                      customer_number: 'abc123') }

  it 'should render customer' do
    @customer = customer
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => customer.id,
      'company_id' => customer.company_id,
      'contact' => {
        'id' => customer.contact.id,
        'name' => 'Joe Customer',
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
      },
      'name' => 'Joe Customer',
      'customer_number' => 'abc123',
      'display_name' => 'Joe Customer',
      'profile_image_url' => nil
    )
  end
end
