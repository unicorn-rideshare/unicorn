require 'rails_helper'

describe 'api/contacts/show' do
  before { allow(GeocodingService).to receive(:geocode).and_return([{ geometry: { location: { latitude: 33.74832, longitude: -84.39111 } } }.with_indifferent_access]) }

  let(:contact) do
    with_resque do
      FactoryGirl.create(
        :contact,
        name: 'Joe User',
        address1: '123 Test St',
        address2: 'Suite 100',
        city: 'Atlanta',
        state: 'GA',
        zip: '30328',
        email: 'test@example.com',
        phone: '1-800-123-4567',
        fax: '1-900-123-4567',
        time_zone_id: 'Eastern Time (US & Canada)',
        mobile: 'm#').reload
    end
  end

  it 'should render contact' do
    @contact = contact
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => contact.id,
                                        'name' => 'Joe User',
                                        'address1' => '123 Test St',
                                        'address2' => 'Suite 100',
                                        'city' => 'Atlanta',
                                        'state' => 'GA',
                                        'zip' => '30328',
                                        'email' => 'test@example.com',
                                        'phone' => '1-800-123-4567',
                                        'fax' => '1-900-123-4567',
                                        'time_zone_id' => 'Eastern Time (US & Canada)',
                                        'latitude' => 33.74832,
                                        'longitude' => -84.39111,
                                        'mobile' => 'm#',
                                        'dob' => nil,
                                        'website' => nil,
                                        'data' => nil,
                                        'description' => nil,
                                    )
  end
end
