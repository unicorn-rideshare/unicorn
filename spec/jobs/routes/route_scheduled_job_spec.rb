require 'rails_helper'

describe RouteScheduledJob do
  let(:route) { FactoryGirl.create(:route, scheduled_start_at: DateTime.now + 5.days) }

  describe '.perform' do
    before do
      allow(Resque).to receive(:enqueue_at)
      allow(Resque).to receive(:remove_delayed)
      allow(RoutingService).to receive(:generate_route)
    end

    it 'should remove any RouteScheduledJob instances already enqueued' do
      expect(Resque).to receive(:remove_delayed).with(RouteStartedStatusCheckupJob, route.id)
      RouteScheduledJob.perform(route.id)
    end

    it 'should recalculate the optimized route' do
      expect(RoutingService).to receive(:generate_route).with(route, route.work_orders)
      RouteScheduledJob.perform(route.id)
    end

    context 'when the route :start_at is not nil' do
      it 'should enqueue a RouteStartedStatusCheckupJob' do
        expect(Resque).to receive(:enqueue_at).with(anything, RouteStartedStatusCheckupJob, route.id)
        RouteScheduledJob.perform(route.id)
      end
    end

    context 'when the route :start_at is nil' do
      let(:route) { FactoryGirl.create(:route, scheduled_start_at: nil) }

      it 'should not enqueue a RouteStartedStatusCheckupJob' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, RouteStartedStatusCheckupJob, route.id)
        RouteScheduledJob.perform(route.id)
      end
    end
  end
end
