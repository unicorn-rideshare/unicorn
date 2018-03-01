require 'rails_helper'

describe WorkOrderProviderEnRouteJob do
  let(:customer_contact_attributes) do
    {
        name: 'Joe Customer',
        address1: 'addr1',
        address2: nil,
        city: 'ATL',
        state: 'GA',
        zip: '30328',
        email: 'u@ex.org',
        phone: 'p#',
        fax: 'f#',
        time_zone_id: 'Eastern Time (US & Canada)',
        mobile: nil
    }
  end

  let(:provider_contact_attributes) do
    {
        name: 'Mark Provider',
        address1: 'addr1',
        address2: nil,
        city: 'ATL',
        state: 'GA',
        zip: '30328',
        email: 'u@ex.org',
        phone: 'p#',
        fax: 'f#',
        time_zone_id: 'Eastern Time (US & Canada)',
        mobile: '+15559876'
    }
  end

  let(:company)     { FactoryGirl.create(:company, name: 'ABC Corp') }
  let(:customer)    { FactoryGirl.create(:customer, company: company, contact_attributes: customer_contact_attributes, name: 'Joe Customer') }
  let(:provider)    { FactoryGirl.create(:provider, :with_user, company: company, contact_attributes: provider_contact_attributes) }
  let(:work_order)  { FactoryGirl.create(:work_order, company: company, customer: customer, scheduled_start_at: DateTime.now + 5.days, started_at: DateTime.now + 5.days) }

  describe '.perform' do
    before do
      work_order.config = { customer_communications: { communications_enabled: true } }
      work_order.save
      
      work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]
      work_order.save

      FactoryGirl.create(:checkin, locatable: provider.user)
      allow(RoutingService).to receive(:driving_eta).and_return(8)

      allow(TwilioService).to receive(:send_sms).with(anything, anything)
      allow(UrlShortenerService).to receive(:shorten).with(anything).and_return('http://example.com/m/e66vx')
      expect(work_order.started_at).not_to be_nil
    end

    context 'when the customer contact does not include a mobile number' do
      it 'should not attempt to send an SMS notification to the customer' do
        expect(TwilioService).not_to receive(:send_sms)
        WorkOrderProviderEnRouteJob.perform(work_order.id)
      end
    end

    context 'when the customer contact includes a mobile number' do
      before { customer.contact.mobile = '+15551234'; customer.contact.save }

      context 'when there is a single work order provider' do
        it 'should send an SMS notification to the customer' do
          expected_body = "Hi Joe! Mark with ABC Corp is on the way to you now and should arrive in 15 minutes! Track Mark's location here: http://example.com/m/e66vx"
          expect(TwilioService).to receive(:send_sms).with(['+15551234'], expected_body)
          WorkOrderProviderEnRouteJob.perform(work_order.id)
        end
      end
    end
  end
end
