require 'rails_helper'

describe WorkOrderStartedStatusCheckupJob do
  let(:work_order) { FactoryGirl.create(:work_order, :scheduled) }

  describe '.perform' do
    context 'when the work order status is :scheduled' do
      it 'should remove any WorkOrderDueAtStatusCheckupJob instances already enqueued' do
        allow(Resque).to receive(:remove_delayed).with(anything, anything)
        expect(Resque).to receive(:remove_delayed).with(WorkOrderDueAtStatusCheckupJob, work_order.id)
        WorkOrderStartedStatusCheckupJob.perform(work_order.id)
      end

      context 'when the work order does not have a :due_at set' do
        it 'should mark the work order as abandoned' do
          WorkOrderStartedStatusCheckupJob.perform(work_order.id)
          expect(work_order.reload.status).to eq('abandoned')
        end
      end

      context 'when the work order has a :due_at set' do
        let(:work_order) { FactoryGirl.create(:work_order, :scheduled_with_due_at) }

        before { allow_any_instance_of(WorkOrder).to receive(:pending_delay?) { true } }

        it 'should mark the work order as delayed' do
          WorkOrderStartedStatusCheckupJob.perform(work_order.id)
          expect(work_order.reload.status).to eq('delayed')
        end

        it 'should enqueue a WorkOrderDelayedJob' do
          expect(Resque).to receive(:enqueue).with(WorkOrderDelayedJob, work_order.id)
          WorkOrderStartedStatusCheckupJob.perform(work_order.id)
        end
      end
    end
  end
end
