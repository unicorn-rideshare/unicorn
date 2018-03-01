require 'rails_helper'

describe 'api/devices/show' do
  let(:device)     { FactoryGirl.create(:device,
                                        apns_device_id: 'some-apns-device-id') }

  it 'should render device' do
    @device = device
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => device.id,
                                        'apns_device_id' => 'some-apns-device-id',
                                        'gcm_registration_id' => nil,
                                        'bundle_id' => nil,
                                        'type' => 'ios',
                                    )
  end
end
