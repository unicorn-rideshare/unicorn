require 'rails_helper'

describe PushWorkOrderProviderRemovedJob do
  let(:company)         { FactoryGirl.create(:company) }
  let(:user)            { FactoryGirl.create(:user) }
  let(:provider)        { FactoryGirl.create(:provider, user: user) }
  let(:work_order)      { FactoryGirl.create(:work_order, company: company) }
  let(:gcm_client)      { double('gcm_client') }
  let(:houston_client)  { double('houston_client') }

  before do
    company.providers << provider
    work_order.work_order_providers.create(provider_id: provider.id)

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
        PushWorkOrderProviderRemovedJob.perform(work_order.id, work_order.provider_ids.first)
      end
    end

    context 'when the user has a gcm_registration_id' do
      before { FactoryGirl.create(:device, user: user, gcm_registration_id: 'gcm_test_registration_id') }

      it 'should use the gcm gem to invoke the Google Cloud Messaging API' do
        expect(gcm_client).to receive(:send_notification)
        PushWorkOrderProviderRemovedJob.perform(work_order.id, work_order.provider_ids.first)
      end
    end
  end
end
