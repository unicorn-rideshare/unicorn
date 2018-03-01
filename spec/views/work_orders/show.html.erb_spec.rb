require 'rails_helper'

describe 'work_orders/show' do
  let(:company)  { FactoryGirl.create(:company) }
  let(:now) { Time.utc(2014, 8, 13) }

  let(:customer_contact_attributes) do
    {
        name: 'Joe User',
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

  let(:provider_contact_attributes) do
    {
        name: 'Tom Ford',
        address1: '1234 Some St',
        address2: nil,
        city: 'Marietta',
        state: 'GA',
        zip: '30062',
        email: 'tom.ford@gmail.com',
        phone: '8005555555',
        fax: 'f#',
        time_zone_id: 'Eastern Time (US & Canada)',
        mobile: 'm#'
    }
  end

  let(:customer) do
    FactoryGirl.create(
        :customer,
        company: company,
        contact_attributes: customer_contact_attributes,
        name: 'Joe User'
    )
  end

  let(:provider) do
    FactoryGirl.create(
        :provider,
        :with_user,
        company: company,
        contact_attributes: provider_contact_attributes,
    )
  end

  let(:status) { nil }

  let(:work_order) do
    FactoryGirl.create(
        :work_order,
        :with_provider,
        status,
        company: company,
        customer: customer,
        description: 'Foo',
        estimated_duration: 52,
        provider_rating: 10,
        scheduled_start_at: now,
        provider: provider
    )
  end

  shared_context 'rendered work order' do
    before do
      [customer.contact, provider.contact].each do |contact|
        contact.latitude = 38.003067
        contact.longitude = -84.583686
      end

      Timecop.freeze(now) do
        @work_order = work_order
        render
      end
    end
  end

  context 'when the work order is disposed' do
    [:completed, :abandoned, :canceled].each do |status|
      context "when the work order status is :#{status.to_s}" do
        include_context 'rendered work order' do
          let(:status) { status }
        end

        it "should render the work order status when current status is #{status.to_s}" do
          expect(rendered).to match /#{status.to_s}/i
        end

        it "should render a facebook login button when current status is #{status.to_s}" do
          expect(rendered).to match /fb-login-button/i
        end
      end
    end
  end

  context 'when the work order is not disposed' do
    [:scheduled, :en_route, :in_progress].each do |status|
      context "when the work order status is :#{status.to_s}" do
        include_context 'rendered work order' do
          let(:status) { status }
        end

        it "should render the work order status when current status is #{status.to_s}" do
          expect(rendered).to match /#{status.to_s}/i
        end

        it "should not render a facebook login button when current status is #{status.to_s}" do
          expect(rendered).to match /fb-login-button/i
        end
      end
    end

    [:scheduled].each do |status|
      context "when the work order status is :#{status.to_s}" do
        include_context 'rendered work order' do
          let(:status) { status }
        end

        it "should render the work order status when current status is #{status.to_s}" do
          expect(rendered).to match /#{status.to_s}/i
        end

        it "should render a facebook login button when current status is #{status.to_s}" do
          expect(rendered).to match /fb-login-button/i
        end
      end
    end
  end
end
