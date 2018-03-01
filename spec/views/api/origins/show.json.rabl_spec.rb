require 'rails_helper'

describe 'api/origins/show' do

  let(:contact_attributes) do
    {
        name: 'Warehouse #4122',
        address1: '1075 Northfield Court',
        address2: 'Ste 400',
        city: 'Roswell',
        state: 'GA',
        zip: '30076',
        email: 'u@ex.org',
        phone: 'p#',
        fax: 'f#',
        time_zone_id: 'Eastern Time (US & Canada)',
        mobile: 'm#',
        dob: nil
    }
  end

  let(:origin) { FactoryGirl.create(:origin, contact_attributes: contact_attributes, warehouse_number: 'abc123') }

  it 'should render origin' do
    @origin = origin
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => origin.id,
                                        'warehouse_number' => 'abc123',
                                        'contact' => {
                                            'id' => origin.contact.id,
                                            'name' => 'Warehouse #4122',
                                            'address1' => '1075 Northfield Court',
                                            'address2' => 'Ste 400',
                                            'city' => 'Roswell',
                                            'state' => 'GA',
                                            'zip' => '30076',
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
                                        'effective_dispatcher_origin_assignments_count' => 0,
                                        'effective_provider_origin_assignments_count' => 0
                                    )
  end
end
