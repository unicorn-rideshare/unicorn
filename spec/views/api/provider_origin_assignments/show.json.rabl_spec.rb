require 'rails_helper'

describe 'api/provider_origin_assignments/show' do
  let(:contact_attributes) do
    {
        name: 'Joe Provider',
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

  let(:provider) { FactoryGirl.create(:provider, :with_user, contact_attributes: contact_attributes) }
  let(:start_date) { Date.today }
  let(:provider_origin_assignment) { FactoryGirl.create(:provider_origin_assignment, provider: provider, start_date: start_date, end_date: start_date) }

  it 'should render provider origin assignment' do
    @provider_origin_assignment = provider_origin_assignment
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => provider_origin_assignment.id,
                                        'status' => 'scheduled',
                                        'provider' => {
                                            'id' => provider.id,
                                            'user_id' => provider.user.id,
                                            'profile_image_url' => provider.user.profile_image_url,
                                            'category_ids' => [],
                                            'contact' => {
                                              'id' => provider.contact.id,
                                              'name' => 'Joe Provider',
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
                                        },
                                        'origin' => Rabl::Renderer.new('origins/show',
                                                                       provider_origin_assignment.origin,
                                                                       view_path: 'app/views',
                                                                       format: 'hash').render.with_indifferent_access,
                                        'start_date' => start_date.iso8601,
                                        'end_date' => start_date.iso8601,
                                        'scheduled_start_at' => nil,
                                        'started_at' => nil,
                                        'ended_at' => nil
                                    )
  end
end
