require 'rails_helper'

describe 'api/dispatcher_origin_assignments/show' do
  let(:contact_attributes) do
    {
        name: 'Joe Dispatcher',
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

  let(:dispatcher) { FactoryGirl.create(:dispatcher, :with_user, contact_attributes: contact_attributes) }
  let(:start_date) { Date.today }
  let(:dispatcher_origin_assignment) { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, start_date: start_date, end_date: start_date) }

  it 'should render dispatcher origin assignment' do
    @dispatcher_origin_assignment = dispatcher_origin_assignment
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => dispatcher_origin_assignment.id,
                                        'dispatcher' => {
                                            'id' => dispatcher.id,
                                            'user_id' => dispatcher.user.id,
                                            'profile_image_url' => dispatcher.user.profile_image_url,
                                            'contact' => {
                                                'id' => dispatcher.contact.id,
                                                'name' => 'Joe Dispatcher',
                                                'address1' => 'addr1',
                                                'address2' => nil,
                                                'city' => 'ATL',
                                                'state' => 'GA',
                                                'zip' => '30328',
                                                'email' => 'u@ex.org',
                                                'phone' => 'p#',
                                                'fax' => 'f#',
                                                'mobile' => 'm#',
                                                'time_zone_id' => 'Eastern Time (US & Canada)',
                                                'latitude' => nil,
                                                'longitude' => nil,
                                                'dob' => nil,
                                                'website' => nil,
                                                'data' => nil,
                                                'description' => nil,
                                            }
                                        },
                                        'origin' => Rabl::Renderer.new('origins/show',
                                                                       dispatcher_origin_assignment.origin,
                                                                       view_path: 'app/views',
                                                                       format: 'hash').render.with_indifferent_access,
                                        'start_date' => start_date.iso8601,
                                        'end_date' => start_date.iso8601
                                    )
  end
end
