require 'rails_helper'

describe WorkOrderDelayedJob do
  let(:work_order) { FactoryGirl.create(:work_order) }

  describe '.perform' do
    it 'should enqueue a WorkOrderEmailJob to notifiy internal parties to escalate' do
      expect(Resque).to receive(:enqueue).with(WorkOrderEmailJob, work_order.id, :due_date_escalation)
      WorkOrderDelayedJob.perform(work_order.id)
    end

    it 'should enqueue a WorkOrderDueAtStatusCheckupJob' do
      expect(Resque).to receive(:enqueue_at).with(anything, WorkOrderDueAtStatusCheckupJob, work_order.id)
      WorkOrderDelayedJob.perform(work_order.id)
    end
  end
end
