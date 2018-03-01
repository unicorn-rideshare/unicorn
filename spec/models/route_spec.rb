require 'rails_helper'

describe Route do
  let(:route)                      { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment) }
  let(:provider_origin_assignment) { FactoryGirl.create(:provider_origin_assignment, start_date: Date.today, end_date: Date.today) }

  it_behaves_like 'notifiable'



  it { should validate_presence_of(:date) }

  it { should validate_presence_of(:dispatcher_origin_assignment) }
  it { should validate_presence_of(:provider_origin_assignment) }

  it { should belong_to(:company) }

  it { should belong_to(:dispatcher_origin_assignment) }
  it { should belong_to(:provider_origin_assignment) }

  it { should have_many(:legs) }
  it { should have_many(:work_orders).through(:legs) }

  it { should have_and_belong_to_many(:items_loaded) }

  it { should have_many(:items_delivered).through(:work_orders) }
  it { should have_many(:items_ordered).through(:work_orders) }
  it { should have_many(:items_rejected).through(:work_orders) }

  describe '#checkins' do
    let(:route) { FactoryGirl.create(:route, :scheduled, provider_origin_assignment: provider_origin_assignment) }

    before do
      Timecop.travel(route.scheduled_start_at.to_time)
      route.start!

      provider = route.provider_origin_assignment.provider

      FactoryGirl.create(:checkin, locatable: provider.user, checkin_at: route.started_at - 4.hours)

      i = 10
      3.times { i += 1; FactoryGirl.create(:checkin, locatable: provider.user, checkin_at: route.started_at + i.minutes) }
    end

    it 'should return a list of the checkins for the provider while the route was in progress' do
      Timecop.travel((route.started_at + 15.minutes).to_time)
      expect(route.checkin_coordinates).to eq([[37.09024, -95.712891], [37.09024, -95.712891], [37.09024, -95.712891]])
    end
  end

  describe '#schedule!' do
    context 'when the route status is :awaiting_schedule' do
      context 'when the operation does not change the :start_at' do
        it 'should not enqueue a RouteScheduledJob' do
          expect(Resque).not_to receive(:enqueue).with(RouteScheduledJob, route.id)
          route.schedule!
        end
      end

      context 'when the operation changes the :start_at' do
        it 'should enqueue a RouteScheduledJob' do
          allow(Resque).to receive(:enqueue).with(anything, anything)
          expect(Resque).to receive(:enqueue).with(RouteScheduledJob, route.id)
          route.scheduled_start_at = DateTime.now + 10.days
          route.schedule!
        end
      end
    end

    context 'when the route status is :scheduled' do
      before { route.scheduled_start_at = DateTime.now + 10.days; route.schedule! }

      context 'when the operation does not change the :start_at' do
        it 'should not enqueue a RouteScheduledJob' do
          expect(Resque).not_to receive(:enqueue).with(RouteScheduledJob, route.id)
          route.schedule!
        end
      end

      context 'when the operation changes the :start_at' do
        it 'should enqueue a RouteScheduledJob' do
          allow(Resque).to receive(:enqueue).with(anything, anything)
          expect(Resque).to receive(:enqueue).with(RouteScheduledJob, route.id)
          route.scheduled_start_at = DateTime.now + 10.days
          route.schedule!
        end
      end
    end
  end

  describe '#start!' do
    let(:route) { FactoryGirl.create(:route, :scheduled, provider_origin_assignment: provider_origin_assignment) }

    context 'when the route status is :scheduled' do
      it 'should set the :started_at timestamp on the route' do
        expect(route.started_at).to be_nil
        route.start!
        expect(route.started_at).not_to be_nil
      end

      it 'should not set the :loading_ended_at timestamp on the route' do
        expect(route.loading_ended_at).to be_nil
        route.start!
        expect(route.loading_ended_at).to be_nil
      end

      it 'should set the status to :in_progress' do
        route.start!
        expect(route.status.downcase.to_sym).to eq(:in_progress)
      end
    end

    context 'when the route status is :loading' do
      before { route.load! }

      it 'should set the :started_at timestamp on the route' do
        expect(route.started_at).to be_nil
        route.start!
        expect(route.started_at).not_to be_nil
      end

      it 'should set the :loading_ended_at timestamp on the route' do
        expect(route.loading_ended_at).to be_nil
        route.start!
        expect(route.loading_ended_at).not_to be_nil
      end

      it 'should set the :loading_duration on the route' do
        expect(route.loading_duration).to be_nil
        route.start!
        expect(route.loading_duration).not_to be_nil
      end

      it 'should set the status to :in_progress' do
        route.start!
        expect(route.status.downcase.to_sym).to eq(:in_progress)
      end
    end
  end

  describe '#cancel!' do
    it 'should enqueue a RouteCanceledJob' do
      allow(Resque).to receive(:enqueue).with(anything, anything)
      expect(Resque).to receive(:enqueue).with(RouteCanceledJob, route.id)
      route.cancel!
    end
  end

  describe '#load!' do
    it 'should set the :loading_started_at timestamp on the route' do
      expect(route.loading_started_at).to be_nil
      route.load!
      expect(route.loading_started_at).not_to be_nil
    end

    it 'should set the provider origin assignment status to :in_progress' do
      expect(route.provider_origin_assignment.status).to eq('scheduled')
      route.load!
      expect(route.reload.provider_origin_assignment.status).to eq('in_progress')
    end
  end

  describe '#unload!' do
    it 'should set the :unloading_started_at timestamp on the route' do
      expect(route.unloading_started_at).to be_nil
      route.unload!
      expect(route.unloading_started_at).not_to be_nil
    end
  end

  describe '#close!' do
    let(:route) { FactoryGirl.create(:route, :scheduled, provider_origin_assignment: provider_origin_assignment) }

    context 'when the route status is :in_progress' do
      before { route.start! }
      
      it 'should not set the :unloading_ended_at timestamp on the route' do
        expect(route.unloading_ended_at).to be_nil
        route.close!
        expect(route.unloading_ended_at).to be_nil
      end

      it 'should set the status to :pending_completion' do
        route.close!
        expect(route.status.downcase.to_sym).to eq(:pending_completion)
      end
    end

    context 'when the route status is :unloading' do
      before { route.load! && route.start! && route.unload! }

      it 'should set the :unloading_ended_at timestamp on the route' do
        expect(route.unloading_ended_at).to be_nil
        route.close!
        expect(route.unloading_ended_at).not_to be_nil
      end

      it 'should set the :unloading_duration on the route' do
        expect(route.unloading_duration).to be_nil
        route.close!
        expect(route.unloading_duration).not_to be_nil
      end

      it 'should set the status to :pending_completion' do
        route.close!
        expect(route.status.downcase.to_sym).to eq(:pending_completion)
      end

      context 'when the provider origin assignment has no more routes to start' do
        it 'should set the provider origin assignment status to :completed' do
          expect(route.provider_origin_assignment.status).to eq('in_progress')
          route.close!
          expect(route.reload.provider_origin_assignment.status).to eq('completed')
        end

        it 'should clock the provider out' do
          expect(route.provider_origin_assignment.status).to eq('in_progress')
          route.close!
          expect(route.reload.provider_origin_assignment.duration).not_to be_nil
        end
      end

      context 'when the provider origin assignment has more routes to start' do
        before { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment, date: Date.today) }

        it 'should not set the provider origin assignment status to :completed' do
          expect(route.provider_origin_assignment.status).to eq('in_progress')
          route.close!
          expect(route.reload.provider_origin_assignment.status).to eq('in_progress')
        end

        it 'should not clock the provider out' do
          expect(route.provider_origin_assignment.status).to eq('in_progress')
          route.close!
          expect(route.reload.provider_origin_assignment.duration).to be_nil
        end
      end
    end
  end

  describe '#complete!' do
    it 'should set the :ended_at timestamp on the route' do
      expect(route.ended_at).to be_nil
      route.complete!
      expect(route.ended_at).not_to be_nil
    end

    it 'should set the :duration on the route' do
      expect(route.duration).to be_nil
      route.complete!
      expect(route.duration).not_to be_nil
    end
  end

  describe '#valid?' do
    let(:route) { FactoryGirl.create(:route,
                                     :with_provider_origin_assignment,
                                     :with_dispatcher_origin_assignment,
                                     date: Date.today) }

    describe ':dispatcher_origin_assignment' do
      let(:dispatcher_origin_assignment)  { route.dispatcher_origin_assignment }

      context 'when the :date is not valid for the :dispatcher_origin_assignment' do
        before do
          dispatcher_origin_assignment.start_date = Date.today + 3.days
          dispatcher_origin_assignment.save
        end

        it 'should now allow the :date to fall outside of the effective date range of the provider origin assignment' do
          route.valid?
          expect(route.errors[:base]).to include(I18n.t('errors.messages.route_date_must_be_valid_for_dispatcher_origin_assignment'))
        end
      end
    end

    describe ':provider_origin_assignment' do
      let(:provider_origin_assignment)  { route.provider_origin_assignment }

      context 'when the :date is not valid for the :provider_origin_assignment' do
        before do
          provider_origin_assignment.start_date = Date.today + 3.days
          provider_origin_assignment.save
        end

        it 'should now allow the :date to fall outside of the effective date range of the provider origin assignment' do
          route.valid?
          expect(route.errors[:base]).to include(I18n.t('errors.messages.route_date_must_be_valid_for_provider_origin_assignment'))
        end
      end
    end
  end

  describe 'the manifest' do
    let(:route)   { FactoryGirl.create(:route,
                                       :with_work_orders_and_items_ordered,
                                       provider_origin_assignment: provider_origin_assignment) }

    describe '#incomplete_manifest?' do
      context 'when the work orders in the route do not contain ordered products which match all loaded products in the route' do
        before do
          route.work_orders.each do |wo|
            route.items_loaded << wo.items_ordered.shuffle.first
          end
        end

        it 'should return true' do
          expect(route.incomplete_manifest?).to eq(true)
        end
      end

      context 'when the work orders in the route contain ordered products which match all loaded products in the route' do
        before do
          route.work_orders.each do |wo|
            wo.items_ordered.shuffle.each do |product|
              route.items_loaded << product
            end
          end
        end

        it 'should return false' do
          expect(route.incomplete_manifest?).to eq(false)
        end
      end

      context 'when the work orders in the route contain some delivered products' do
        context 'when no products have been rejected' do
          before do
            route.work_orders.each do |wo|
              wo.items_ordered.shuffle.each do |product|
                route.items_loaded << product
              end
            end

            route.reload

            wo = route.work_orders.first
            wo.items_delivered = [wo.items_ordered.first]

            i = route.items_loaded.find_index { |product| product == wo.items_ordered.first }
            items_loaded = route.items_loaded.to_a
            items_loaded.delete_at(i)
            route.items_loaded = []
            route.items_loaded = items_loaded
          end

          it 'should return false' do
            expect(route.incomplete_manifest?).to eq(false)
          end
        end

        context 'when some products have been rejected' do
          before do
            route.work_orders.each do |wo|
              wo.items_ordered.shuffle.each do |product|
                route.items_loaded << product
              end
            end

            route.reload

            wo = route.work_orders.first
            wo.items_delivered = [wo.items_ordered.first]
            wo.items_rejected = [wo.items_ordered.second]

            i = route.items_loaded.find_index { |product| product == wo.items_ordered.first }
            items_loaded = route.items_loaded.to_a
            items_loaded.delete_at(i)
            route.items_loaded = []
            route.items_loaded = items_loaded
          end

          it 'should return false' do
            expect(route.incomplete_manifest?).to eq(false)
          end
        end
      end

      context 'when the work orders in the route consist of rejected products' do
        before do
          route.work_orders.each do |wo|
            wo.items_ordered.shuffle.each do |product|
              route.items_loaded << product
              wo.items_rejected << product
            end
          end
        end

        it 'should return false' do
          expect(route.incomplete_manifest?).to eq(false)
        end
      end
    end

    describe '#manifest_requires_gtin?' do
      context 'when the given product gtin needs to be loaded one or more times to complete the manifest' do
        context 'when none of the ordered products have been loaded' do
          it 'should return true for all product gtins' do
            route.work_orders.each do |wo|
              wo.items_ordered.each do |product|
                expect(route.manifest_requires_gtin?(product.gtin)).to eq(true)
              end
            end
          end
        end

        context 'when all of the ordered products have been loaded' do
          before do
            route.work_orders.each do |wo|
              wo.items_ordered.shuffle.each do |product|
                route.items_loaded << product
              end
            end
          end

          it 'should return false for all product gtins' do
            route.work_orders.each do |wo|
              wo.items_ordered.each do |product|
                expect(route.manifest_requires_gtin?(product.gtin)).to eq(false)
              end
            end
          end
        end

        context 'when all of the ordered products have been loaded' do
          before do
            route.work_orders.each do |wo|
              wo.items_delivered = wo.items_ordered.shuffle
            end
          end

          it 'should return false for all product gtins' do
            route.work_orders.each do |wo|
              wo.items_delivered.each do |product|
                expect(route.manifest_requires_gtin?(product.gtin)).to eq(false)
              end
            end
          end
        end
      end

      context 'when the given product gtin does not need to be loaded to complete the manifest' do
        it 'should return false' do
          expect(route.manifest_requires_gtin?('some-gtin')).to eq(false)
        end
      end
    end
  end
end
