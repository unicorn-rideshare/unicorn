require 'rails_helper'

describe 'api/work_orders/show' do
  let(:company)  { FactoryGirl.create(:company) }
  let(:now) { Time.utc(2014, 8, 13) }

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
      mobile: 'm#'
    }
  end

  let(:provider_contact_attributes) do
    {
      name: 'Sam Provider',
      address1: '1234 Some St',
      address2: nil,
      city: 'Marietta',
      state: 'GA',
      zip: '30062',
      email: 'tom.ford@gmail.com',
      phone: '6789389248',
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
      name: 'Joe Customer'
    )
  end

  let(:job) do
    FactoryGirl.create(
        :job,
        company: company
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

  let(:started_at)  { now + (1.5).hours }

  let(:work_order) do
    FactoryGirl.create(
      :work_order,
      :with_provider,
      company: company,
      customer: customer,
      job: job,
      description: 'Foo',
      estimated_duration: 52,
      provider_rating: 10,
      scheduled_start_at: now,
      scheduled_end_at: now + 52.minutes,
      provider: provider,
      started_at: started_at,
      arrived_at: started_at + 19.minutes,
      ended_at: started_at + (1.5).hours,
      abandoned_at: started_at + (2.5).hours,
      canceled_at: started_at + (3.5).hours
    )
  end

  it 'should render work order' do
    @include_products = true
    @include_work_order_providers = true

    Timecop.freeze(now) do
      @work_order = work_order
      render
      expect(JSON.parse(rendered)).to eq(
        'id' => work_order.id,
        'company_id' => company.id,
        'customer_id' => customer.id,
        'job_id' => job.id,
        'description' => 'Foo',
        'status' => Settings.app.default_work_order_status,
        'duration' => 5400.0,
        'estimated_duration' => 52,
        'started_at' => '2014-08-13T01:30:00Z',
        'arrived_at' => '2014-08-13T01:49:00Z',
        'ended_at' => '2014-08-13T03:00:00Z',
        'abandoned_at' => '2014-08-13T04:00:00Z',
        'canceled_at' => '2014-08-13T05:00:00Z',
        'submitted_for_approval_at' => nil,
        'approved_at' => nil,
        'rejected_at' => nil,
        'config' => {},
        'priority' => nil,
        'price' => nil,
        'materials' => [],
        'category' => nil,
        'category_id' => nil,
        'customer_rating' => nil,
        'customer' => {
          'id' => customer.id,
          'company_id' => customer.company_id,
          'name' => 'Joe Customer',
          'customer_number' => nil,
          'display_name' => 'Joe Customer',
          'profile_image_url' => nil,
          'contact' => {
            'id' => customer.contact.id,
            'name' => 'Joe Customer',
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
            'data' => nil,
            'description' => nil,
          },
        },
        'estimated_distance' => nil,
        'estimated_price' => nil,
        'job' => {
            'id' => work_order.job_id,
            'company_id' => work_order.job.company_id,
            'customer_id' => work_order.job.customer_id,
            'config' => {},
            'name' => nil,
            'type' => work_order.job.type,
            'status' => 'configuring',
            'quoted_price_per_sq_ft' =>nil,
            'work_orders_count' => 0
        },
        'user' => nil,
        'user_id' => nil,
        'user_rating' => nil,
        'work_order_providers' => [
          {
            'id' => work_order.work_order_providers.first.id,
            'confirmed_at' => nil,
            'estimated_duration' => nil,
            'estimated_cost' => nil,
            'estimated_revenue' => nil,
            'hourly_rate' => nil,
            'hourly_rate_due' => nil,
            'flat_fee' => nil,
            'flat_fee_due' => nil,
            'duration' => nil,
            'rating' => nil,
            'started_at' => nil,
            'ended_at' => nil,
            'arrived_at' => nil,
            'abandoned_at' => nil,
            'canceled_at' => nil,
            'timed_out_at' => nil,
            'provider' => {
              'id' => provider.id,
              'user_id' => provider.user.id,
              'available' => false,
              'profile_image_url' => provider.user.profile_image_url,
              'category_ids' => [],
              'contact' => {
                'id' => provider.contact.id,
                'name' => 'Sam Provider',
                'address1' => '1234 Some St',
                'address2' => nil,
                'city' => 'Marietta',
                'state' => 'GA',
                'zip' => '30062',
                'email' => 'tom.ford@gmail.com',
                'phone' => '6789389248',
                'fax' => 'f#',
                'mobile' => 'm#',
                'time_zone_id' => 'Eastern Time (US & Canada)',
                'latitude' => nil,
                'longitude' => nil,
                'dob' => nil,
                'website' => nil,
                'data' => nil,
                'description' => nil,
              },
              'last_checkin_at' => nil,
              'last_checkin_latitude' => nil,
              'last_checkin_longitude' => nil,
              'last_checkin_heading' => nil,
            }
          }
        ],
        'provider_rating' => 10,
        'scheduled_start_at' => '2014-08-13T00:00:00Z',
        'scheduled_end_at' => '2014-08-13T00:52:00Z',
        'due_at' => nil,
        'items_delivered' => [],
        'items_ordered' => [],
        'items_rejected' => [],
      )
    end
  end

  %w(items_delivered items_ordered).each do |product_key|
    context "when the work order has #{product_key}" do
      let(:product) { FactoryGirl.create(:product) }
      before do
        @include_products = true
        @include_work_order_providers = true

        Timecop.freeze(now) do
          work_order.send("#{product_key}").send('<<', product)
        end
      end

      it "should render the #{product_key} for the work order" do
        @work_order = work_order
        render
        expect(JSON.parse(rendered)[product_key].size).to eq(1)
      end
    end
  end
end
