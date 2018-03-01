require 'rails_helper'

describe WorkOrder do
  let(:work_order) { FactoryGirl.create(:work_order) }
  let(:now) { Time.utc(2014, 7, 16) }

  it_behaves_like 'attachable'
  it_behaves_like 'commentable'
  it_behaves_like 'expensable'
  it_behaves_like 'notifiable'

  it { should belong_to(:company) }

  it { should belong_to(:category) }

  it { should belong_to(:customer) }

  it { should belong_to(:job) }

  it { should belong_to(:origin) }
  it { should belong_to(:route_leg) }

  it { should have_many(:tasks) }

  it { should validate_inclusion_of(:customer_rating).in_range(0..10).allow_nil }
  it { should validate_numericality_of(:customer_rating).only_integer.allow_nil }

  it { should validate_inclusion_of(:provider_rating).in_range(0..10).allow_nil }
  it { should validate_numericality_of(:provider_rating).only_integer.allow_nil }

  it { should have_and_belong_to_many(:items_ordered) }
  it { should have_and_belong_to_many(:items_delivered) }
  it { should have_and_belong_to_many(:items_rejected) }

  it { should have_many(:work_order_providers) }
  it { should accept_nested_attributes_for(:work_order_providers) }

  before { Timecop.freeze(now) }

  describe 'deferred_scheduling_due' do
    let(:preferred_scheduled_start_date) { Date.today + 7.days }
    let(:work_order) { FactoryGirl.create(:work_order, preferred_scheduled_start_date: preferred_scheduled_start_date) }
    let(:customer) { work_order.customer }

    before do
      customer.config = { customer_communications: { email_scheduled_confirmation_offset: 7.days.seconds * -1 } }
      customer.save

      Timecop.freeze((work_order.preferred_scheduled_start_date - customer.communications_config[:email_scheduled_confirmation_offset].seconds).to_datetime)
    end

    it 'should return the work orders that are due for deferred scheduling' do
      date = (DateTime.now.utc + work_order.customer_communications_config[:email_scheduled_confirmation_offset].seconds)
      expect(WorkOrder.deferred_scheduling_due(date).to_a).to eq([work_order])
    end
  end

  describe 'ordered_by_distance_from_coordinate' do
    let(:origin)          { FactoryGirl.create(:origin) }

    let(:work_order1)     { FactoryGirl.create(:work_order,
                                               company: origin.market.company,
                                               customer: FactoryGirl.create(:customer, company: origin.market.company),
                                               origin: origin) }

    let(:work_order2)     { FactoryGirl.create(:work_order,
                                               company: origin.market.company,
                                               customer: FactoryGirl.create(:customer, company: origin.market.company),
                                               origin: origin) }

    let(:work_order3)     { FactoryGirl.create(:work_order,
                                               company: origin.market.company,
                                               customer: FactoryGirl.create(:customer, company: origin.market.company),
                                               origin: origin) }

    let(:edgewood_coord)    { Coordinate.new(33.757211, -84.340866) }
    let(:origin_coord)      { edgewood_coord }

    # coords in order from nearest to farthest from edgewood are: midtown, druid_hills, buckhead
    let(:buckhead_coord)    { Coordinate.new(33.840519, -84.383438) }
    let(:druid_hills_coord) { Coordinate.new(33.778331, -84.334686) }
    let(:midtown_coord)     { Coordinate.new(33.783325, -84.383266) }
    let(:customer_coords)   { [druid_hills_coord, midtown_coord, buckhead_coord].shuffle }

    before do
      origin_contact = origin.contact
      origin_contact.skip_geocode = true
      origin_contact.latitude = origin_coord.latitude
      origin_contact.longitude = origin_coord.longitude
      origin_contact.save

      [work_order1, work_order2, work_order3].each do |wo|
        coord = customer_coords.shift

        customer = wo.customer
        contact = customer.contact
        contact.skip_geocode = true
        contact.latitude = coord.latitude
        contact.longitude = coord.longitude
        contact.save
      end
    end

    it 'should return the work orders ordered by distance from the origin coordinate' do
      ordered_coords_by_distance_from_origin = [druid_hills_coord, midtown_coord, buckhead_coord]
      work_orders_ordered_by_distance = origin.work_orders.ordered_by_distance_from_coordinate(origin_coord)
      expect(work_orders_ordered_by_distance.map(&:customer).flatten.map(&:contact).flatten.map(&:coordinate)).to eql(ordered_coords_by_distance_from_origin)
    end
  end

  describe '#config' do
    describe '#customer_communications_config' do
      it 'should return the :work_orders -> :customer_communications settings object' do
        expect(work_order.customer_communications_config).to_not be_nil
      end
    end
  end

  describe '#valid?' do
    it 'should not allow the category to change' do
      new_category = FactoryGirl.create(:category)
      work_order.update_attributes(category: new_category) && true
      expect(work_order.errors[:category_id]).to include("can't be changed")
    end

    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      work_order.update_attributes(company: new_company) && true
      expect(work_order.errors[:company_id]).to include("can't be changed")
    end

    it 'should not allow the customer to change' do
      new_customer = FactoryGirl.create(:customer)
      work_order.update_attributes(customer: new_customer) && true
      expect(work_order.errors[:customer_id]).to include("can't be changed")
    end

    it 'should not associate another companies customers' do
      our_company = FactoryGirl.create(:company)
      their_customer = FactoryGirl.create(:customer)
      work_order = WorkOrder.new(company: our_company, customer: their_customer)
      work_order.valid?
      expect(work_order.errors[:customer_id]).to include("doesn't match Work Order's Company")
    end

    context 'the customer was not specified' do
      it 'should not validate the customers company' do
        our_company = FactoryGirl.create(:company)
        work_order = WorkOrder.new(company: our_company, customer: nil)
        work_order.valid?
        expect(work_order.errors[:customer_id]).to_not include("doesn't match Work Order's Company")
      end
    end

    context 'scheduled_start_at' do
      let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

      it 'should not allow the work order :scheduled_start_at to be set in the past' do
        work_order.scheduled_start_at = DateTime.now - 1.minute
        work_order.valid?
        expect(work_order.errors[:scheduled_start_at]).to include("can't be in the past")
      end
    end

    context 'the origin' do
      context 'when the origin is not nil' do
        it 'should associate the work order with an origin in a market that belongs to our company' do
          our_company = FactoryGirl.create(:company)
          our_origin = FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: our_company))
          work_order = WorkOrder.new(company: our_company, origin: our_origin)
          work_order.valid?
          expect(work_order.errors[:origin_id]).to_not include("doesn't match Work Order's Market")
        end

        it 'should not associate the work order with an origin in a market that does not belong to our company' do
          our_company = FactoryGirl.create(:company)
          work_order = WorkOrder.new(company: our_company, origin: FactoryGirl.create(:origin))
          work_order.valid?
          expect(work_order.errors[:origin_id]).to include("doesn't match Work Order's Market")
        end
      end
    end

    context 'the work order status' do
      it 'should validate the status to be included in WorkOrderStatus#all' do
        work_order = FactoryGirl.build(:work_order, :status => :invalid_status)
        work_order.valid?
        expect(work_order.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe 'the default work order status' do
    it "should be initialized to #{Settings.app.default_work_order_status}" do
      expect(work_order.status).to eq(Settings.app.default_work_order_status)
    end
  end

  describe '#disposed?' do
    [
        :abandoned,
        :completed,
        :canceled
    ].each do |status|
      it "should return true for :#{status.to_s}" do
        work_order = FactoryGirl.create(:work_order, status)
        expect(work_order.disposed?).to eq(true)
      end
    end
  end

  describe 'initial providers' do
    let(:company)    { FactoryGirl.create(:company) }
    let(:provider)   { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:work_order) { FactoryGirl.create(:work_order, :with_provider, company: company, provider: provider) }

    it 'should add the :provider role to each provider for the work order' do
      expect(provider.user.has_role?(:provider, work_order)).to eq(true)
    end
  end

  describe '#save' do
    let(:provider)    { FactoryGirl.create(:provider, :with_user) }
    let(:work_order)  { FactoryGirl.create(:work_order, company: provider.company) }

    context 'when a provider is added' do
      subject do
        work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]
      end

      it 'should enqueue a PushWorkOrderProviderAddedJob' do
        allow(Resque).to receive(:enqueue).with(GeocodeContactJob, anything)
        allow(Resque).to receive(:enqueue).with(anything, anything, anything)
        expect(Resque).to receive(:enqueue).with(PushWorkOrderProviderAddedJob, work_order.id, provider.id)
        subject
      end

      it 'should add the :provider role to the added provider user for the work order instance' do
        expect { subject }.to change { provider.user.roles.count }.by(1)
        expect(provider.user.has_role?(:provider, work_order)).to eq(true)
      end
    end

    context 'when a provider is removed' do
      let(:provider)    { FactoryGirl.create(:provider, :with_user) }
      let(:work_order)  { FactoryGirl.create(:work_order, company: provider.company) }

      before do
        work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]
        work_order.save
      end

      subject do
        work_order.work_order_providers_attributes = []
        work_order.save
      end

      it 'should enqueue a PushWorkOrderProviderRemovedJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        allow(Resque).to receive(:enqueue).with(anything, anything, anything)
        expect(Resque).to receive(:enqueue).with(PushWorkOrderProviderRemovedJob, work_order.id, provider.id)
        subject
      end

      it 'should remove the :provider role from the removed provider user for the work order instance' do
        expect(provider.user.has_role?(:provider, work_order)).to eq(true)
        expect { subject }.to change { provider.user.roles.count }.by(-1)
        expect(provider.user.has_role?(:provider, work_order)).to eq(false)
      end
    end

    context 'when a work order product is added' do
      let(:job_product) { FactoryGirl.create(:job, :with_materials, company: work_order.company).materials.first }
      before { job_product.job.work_orders << work_order }

      subject do
        work_order.work_order_products_attributes = [ { job_product_id: job_product.id } ]
        work_order.save
      end

      it 'should add the work order product to the work order instance' do
        expect(work_order.reload.materials.size).to eq(0)
        expect { subject }.to change { work_order.materials.count }.by(1)
        expect(work_order.reload.materials.first.job_product).to eq(job_product)
      end
    end

    context 'when a work order product is removed' do
      let(:job_product) { FactoryGirl.create(:job, :with_materials, company: work_order.company).materials.first }

      before do
        job_product.job.work_orders << work_order

        work_order.work_order_products_attributes = [ { job_product_id: job_product.id } ]
        work_order.save
      end

      subject do
        work_order.work_order_products_attributes = []
        work_order.save
      end

      it 'should remove the work order product to the work order instance' do
        expect(work_order.reload.materials.first.job_product).to eq(job_product)
        expect { subject }.to change { work_order.materials.count }.by(-1)
        expect(work_order.reload.materials).to eq([])
      end
    end
  end

  describe '#duration' do
    context 'when the :started_at and :ended_at timestamps are not nil' do
      let(:started_at)  { DateTime.now - 3.hours }

      before do
        work_order.started_at = started_at
        work_order.ended_at = started_at + 3.hours
      end

      it 'should return 3.hours' do
        expect(work_order.duration).to eq(3.hours)
      end
    end

    context 'when the :started_at timestamp is nil' do
      it 'should return nil' do
        expect(work_order.duration).to be_nil
      end
    end

    context 'when the :ended_at timestamp is nil' do
      before do
        work_order.started_at = DateTime.now - 3.hours
      end

      it 'should return nil' do
        expect(work_order.duration).to be_nil
      end
    end
  end

  describe 'state machine' do
    describe 'awaiting_schedule' do
      context 'when the :preferred_scheduled_start_date is nil' do
        let(:work_order) { FactoryGirl.build(:work_order, status: 'awaiting_schedule') }

        it 'should not be valid' do
          expect(work_order.valid?).to be_falsey
        end
      end

      context 'when the preferred_scheduled_start_date is not nil' do
        let(:work_order) { FactoryGirl.build(:work_order, :awaiting_schedule) }

        it 'should be valid' do
          expect(work_order.valid?).to be_truthy
        end
      end
    end

    describe '#schedule!' do
      context 'when the operation does not change the :scheduled_start_at' do
        it 'should not enqueue a WorkOrderScheduledJob' do
          expect(Resque).not_to receive(:enqueue).with(WorkOrderScheduledJob, work_order.id)
          work_order.schedule!
        end
      end

      context 'when the operation changes the :scheduled_start_at' do
        it 'should enqueue a WorkOrderScheduledJob' do
          allow(Resque).to receive(:enqueue).with(anything, anything)
          expect(Resque).to receive(:enqueue).with(WorkOrderScheduledJob, work_order.id)
          work_order.scheduled_start_at = DateTime.now + 10.days
          work_order.schedule!
        end
      end
    end

    describe '#delay!' do
      let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

      before { allow(work_order).to receive(:pending_delay?) { true } }

      it 'should enqueue a WorkOrderDelayedJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        expect(Resque).to receive(:enqueue).with(WorkOrderDelayedJob, work_order.id)
        work_order.delay!
      end
    end

    describe '#start!' do
      context 'when the work order status is :scheduled' do
        let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

        it 'should set the :started_at timestamp on the work order' do
          expect(work_order.started_at).to be_nil
          work_order.start!
          expect(work_order.started_at).not_to be_nil
        end

        it 'should not set the :arrived_at timestamp on the work order' do
          expect(work_order.arrived_at).to be_nil
          work_order.start!
          expect(work_order.arrived_at).to be_nil
        end
      end

      context 'when the work order status is :en_route' do
        let(:work_order) { FactoryGirl.create(:work_order, :en_route) }

        it 'should not change the :started_at timestamp on the work order' do
          expected_started_at = work_order.started_at
          work_order.start!
          expect(work_order.started_at).to eq(expected_started_at)
        end

        it 'should set the :arrived_at timestamp on the work order' do
          expect(work_order.arrived_at).to be_nil
          work_order.start!
          expect(work_order.arrived_at).not_to be_nil
        end

        it 'should set the :driving_duration on the work order' do
          expect(work_order.driving_duration).to be_nil
          work_order.start!
          expect(work_order.driving_duration).not_to be_nil
        end
      end
    end

    describe '#complete!' do
      let(:work_order) { FactoryGirl.create(:work_order, :in_progress) }

      it 'should set the :ended_at timestamp on the work order' do
        expect(work_order.ended_at).to be_nil
        work_order.complete!
        expect(work_order.ended_at).not_to be_nil
      end

      it 'should set the :work_duration timestamp on the work order' do
        expect(work_order.work_duration).to be_nil
        work_order.complete!
        expect(work_order.work_duration).not_to be_nil
      end

      it 'should enqueue a WorkOrderCompletedJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        expect(Resque).to receive(:enqueue).with(WorkOrderCompletedJob, work_order.id)
        work_order.complete!
      end
    end

    describe '#abandon!' do
      let(:work_order) { FactoryGirl.create(:work_order, :in_progress) }

      it 'should set the :abandoned_at timestamp on the work order' do
        expect(work_order.abandoned_at).to be_nil
        work_order.abandon!
        expect(work_order.abandoned_at).not_to be_nil
      end

      it 'should set the :waiting_duration on the work order' do
        expect(work_order.waiting_duration).to be_nil
        work_order.abandon!
        expect(work_order.waiting_duration).not_to be_nil
      end

      it 'should enqueue a WorkOrderAbandonedJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        expect(Resque).to receive(:enqueue).with(WorkOrderAbandonedJob, work_order.id)
        work_order.abandon!
      end
    end

    describe '#cancel!' do
      let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

      it 'should set the :canceled_at timestamp on the work order' do
        expect(work_order.canceled_at).to be_nil
        work_order.cancel!
        expect(work_order.canceled_at).not_to be_nil
      end

      it 'should remove delayed WorkOrderEmailJob jobs for the work order' do
        expect(Resque).to receive(:remove_delayed).with(WorkOrderConfirmationStatusCheckupJob, work_order.id)
        expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :scheduled_confirmation)
        expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :reminder)
        expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :morning_of_reminder)
        work_order.cancel!
      end

      it 'should enqueue a WorkOrderCanceledJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        expect(Resque).to receive(:enqueue).with(WorkOrderCanceledJob, work_order.id)
        work_order.cancel!
      end
    end

    describe '#route!' do
      let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

      it 'should set the :started_at timestamp on the work order' do
        expect(work_order.started_at).to be_nil
        work_order.route!
        expect(work_order.started_at).not_to be_nil
      end

      it 'should enqueue a WorkOrderProviderEnRouteJob' do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        expect(Resque).to receive(:enqueue).with(WorkOrderProviderEnRouteJob, work_order.id)

        work_order.route!
      end
    end

    describe '#reschedule!' do
      let(:work_order) { FactoryGirl.create(:work_order, :abandoned, abandoned_at: DateTime.now - 5.minutes) }
      before { expect(work_order.abandoned_at).to_not be_nil }

      it 'should clear the previously set :abandoned_at' do
        work_order.scheduled_start_at = DateTime.now
        work_order.reschedule!
        expect(work_order.reload.abandoned_at).to be_nil
      end
    end
  end

  describe '#customer_communications_config' do
    let(:company)     { FactoryGirl.create(:company) }
    let(:customer)    { FactoryGirl.create(:customer, company: company) }
    let(:work_order)  { FactoryGirl.create(:work_order, company: company, customer: customer) }

    before do
      [work_order, work_order.customer, work_order.company].each do |obj|
        obj.config = { customer_communications: { exposes_status_publicly: nil, rating_request_dial_offset: nil } }
        obj.save
      end
    end

    context 'when the work order settings have not been modified from default values' do
      before do
        company.config = { customer_communications: { exposes_status_publicly: true } }
        company.save
      end

      it 'should return the company communications config' do
        expect(work_order.customer_communications_config[:exposes_status_publicly]).to eq(true)
      end
    end

    context 'when the work_order settings have been modified from default values' do
      before do
        work_order.config = { customer_communications: { rating_request_dial_offset: 1000 } }
        work_order.save
      end

      it 'should return the customer communications config' do
        expect(work_order.customer_communications_config[:rating_request_dial_offset]).to eq(1000)
      end
    end
  end

  describe '#estimated_cost' do
    subject { work_order.estimated_cost }

    it 'should return 0.00' do
      expect(subject).to eq(0.0)
    end
  end
end
