require 'rails_helper'

describe PushTaskDelegationNotificationsJob do
  let(:company)         { FactoryGirl.create(:company) }
  let(:provider)        { FactoryGirl.create(:provider, :with_user, company: company) }
  let(:task)            { FactoryGirl.create(:task, company: company, provider: provider) }
  let(:user)            { provider.user }
  let(:gcm_client)      { double('gcm_client') }
  let(:houston_client)  { double('houston_client') }

  before do
    Rails.application.config.gcm_client = gcm_client
    Rails.application.config.default_houston_client = houston_client

    allow(gcm_client).to receive(:send_notification)
    allow(houston_client).to receive(:push)
  end

  describe '.perform' do
    subject { PushTaskDelegationNotificationsJob.perform(task.id) }

    context 'when the provider has an apns_device_id' do
      before { FactoryGirl.create(:device, user: user, apns_device_id: 'apns_test_device_id') }

      it 'should use the houston gem to invoke the APNS' do
        expect(houston_client).to receive(:push)
        subject
      end
    end

    context 'when the recipient has a gcm_registration_id' do
      before { FactoryGirl.create(:device, user: user, gcm_registration_id: 'gcm_test_registration_id') }

      it 'should use the gcm gem to invoke the Google Cloud Messaging API' do
        expect(gcm_client).to receive(:send_notification)
        subject
      end
    end

    it 'should trigger a websocket :push event notification to the recipient user channel' do
      channel = WebsocketRails["user_#{user.id}"]
      expect(channel).to receive(:trigger).with(:push, anything).exactly(1).times
      subject
    end
  end
end
