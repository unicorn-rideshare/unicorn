require 'rails_helper'

describe PurgeInvalidDevicesJob do
  let(:gcm_client)            { double('gcm_client') }
  let(:houston_client)        { double('houston_client') }

  let(:expired_apns_token_1)  { "018744cc a58fb5b3 de015f4a b5f6ea98 f7b9da92 fb295c77 d62f8f81 960118d4" }
  let(:expired_apns_token_2)  { "9a10c5e1 724667ee 0ee650f8 f7061844 13d907e7 88d9e4c3 2a9826cb 807a9ffd" }
  let(:expired_apns_token_3)  { "ed790afe b55d29ed 7e896fde 4059d5fd b24b3819 202de9da e06c1c45 20be51c4" }

  let(:invalid_apns_device_1) { FactoryGirl.create(:device, apns_device_id: "<#{expired_apns_token_1}>") }
  let(:invalid_apns_device_2) { FactoryGirl.create(:device, apns_device_id: "<#{expired_apns_token_2}>") }
  let(:invalid_apns_device_3) { FactoryGirl.create(:device, apns_device_id: "<#{expired_apns_token_3}>") }

  before do
    Rails.application.config.gcm_client = gcm_client
    Rails.application.config.houston_client = houston_client

    allow(houston_client).to receive(:devices) { [expired_apns_token_1, expired_apns_token_2, expired_apns_token_3] }
  end

  describe '.perform' do
    context 'when there are devices with expired apns device ids' do
      before { invalid_apns_device_1 && invalid_apns_device_2 && invalid_apns_device_3 }

      it 'should delete the invalid devices' do
        expect(Device.count).to eq(3)
        PurgeInvalidDevicesJob.perform
        expect(Device.count).to eq(0)
      end
    end
  end
end
