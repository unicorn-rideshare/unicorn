require 'rails_helper'

describe PushMessageNotificationsJob do
  let(:sender)          { FactoryGirl.create(:user) }
  let(:recipient)       { FactoryGirl.create(:user) }
  let(:message)         { FactoryGirl.create(:message, sender: sender, recipient: recipient, body: 'hello there, im a message') }
  let(:gcm_client)      { double('gcm_client') }
  let(:houston_client)  { double('houston_client') }

  before do
    Rails.application.config.gcm_client = gcm_client
    Rails.application.config.houston_client = houston_client
    Rails.application.config.default_houston_client = houston_client

    allow(gcm_client).to receive(:send_notification)
    allow(houston_client).to receive(:push)
  end

  describe '.perform' do
    context 'when the recipient has an apns_device_id' do
      before do
        FactoryGirl.create(:device, user: recipient, apns_device_id: 'apns_test_device_id')
      end

      it 'should use the houston gem to invoke the APNS' do
        expect(houston_client).to receive(:push)
        PushMessageNotificationsJob.perform(message.id)
      end
    end

    context 'when the recipient has a gcm_registration_id' do
      before do
        FactoryGirl.create(:device, user: recipient, gcm_registration_id: 'gcm_test_registration_id')
      end

      it 'should use the gcm gem to invoke the Google Cloud Messaging API' do
        expect(gcm_client).to receive(:send_notification)
        PushMessageNotificationsJob.perform(message.id)
      end
    end

    it 'should trigger a websocket :push event notification to the recipient user channel' do
      channel = WebsocketRails["user_#{message.recipient.id}"]
      expect(channel).to receive(:trigger).with(:push, anything).exactly(1).times
      PushMessageNotificationsJob.perform(message.id)
    end
  end
end
