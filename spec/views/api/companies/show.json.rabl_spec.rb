require 'rails_helper'

describe 'api/companies/show' do
  let(:contact_attributes) do
    {
      name: 'ABC Corp',
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

  let(:company) do
    FactoryGirl.create(
      :company,
      contact_attributes: contact_attributes,
      name: 'ABC Corp')
  end

  it 'should render company' do
    @company = company
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => company.id,
      'user_id' => company.user_id,
      'contact' => {
        'id' => company.contact.id,
        'name' => 'ABC Corp',
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
      'name' => 'ABC Corp',
      'config' => {},
      'stripe_customer_id' => nil,
      'stripe_credit_card_id' => nil,
    )
  end
end
