require 'rails_helper'

describe PushNotificationJob do
  let(:user)            { FactoryGirl.create(:user) }
  let(:notification)    { FactoryGirl.create(:notification, recipient: user) }
  let(:gcm_client)      { double('gcm_client') }
  let(:houston_client)  { double('houston_client') }

  before do
    Rails.application.config.gcm_client = gcm_client
    Rails.application.config.default_houston_client = houston_client

    allow(gcm_client).to receive(:send_notification)
    allow(houston_client).to receive(:push)
  end

  describe '.perform' do
    context 'when the user has an apns_device_id' do
      before { FactoryGirl.create(:device, user: user, apns_device_id: 'apns_test_device_id') }

      it 'should use the houston gem to invoke the APNS' do
        expect(houston_client).to receive(:push)
        PushNotificationJob.perform(notification.id)
      end
    end

    context 'when the user has a gcm_registration_id' do
      before { FactoryGirl.create(:device, user: user, gcm_registration_id: 'gcm_test_registration_id') }

      it 'should use the gcm gem to invoke the Google Cloud Messaging API' do
        expect(gcm_client).to receive(:send_notification)
        PushNotificationJob.perform(notification.id)
      end
    end
  end
end
