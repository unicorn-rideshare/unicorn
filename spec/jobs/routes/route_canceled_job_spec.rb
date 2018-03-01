require 'rails_helper'

describe RouteCanceledJob do
  let(:route)       { FactoryGirl.create(:route, :with_provider_origin_assignment, scheduled_start_at: DateTime.now + 5.days) }
  let(:work_order1) { FactoryGirl.create(:work_order, :completed, company: route.provider_origin_assignment.provider.company) }
  let(:work_order2) { FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company) }

  before do
    route.legs.create(work_order: work_order1)
    route.legs.create(work_order: work_order2)
  end

  describe '.perform' do
    before do
      allow(Resque).to receive(:enqueue_at)
      allow(Resque).to receive(:remove_delayed)
    end

    it 'should cancel any work orders that have not been disposed of' do
      expect_any_instance_of(WorkOrder).to receive(:cancel!)
      RouteCanceledJob.perform(route.id)
    end
  end
end
