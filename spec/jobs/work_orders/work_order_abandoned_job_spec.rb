require 'rails_helper'

describe WorkOrderAbandonedJob do
  let(:work_order)  { FactoryGirl.create(:work_order, abandoned_at: DateTime.now) }

  describe '.perform' do
    before do
      work_order.config = { customer_communications: { communications_enabled: true } }
      work_order.save
      
      expect(work_order.abandoned_at).not_to be_nil
    end

    it 'should set the :abandoned_at timestamp' do
      WorkOrderAbandonedJob.perform(work_order.id)
      expect(work_order.reload.abandoned_at).to_not be_nil
    end

    it 'should enqueue a WorkOrderEmailJob to notify customer service' do
      expect(Resque).to receive(:enqueue).with(WorkOrderEmailJob, work_order.id, :customer_service_notification)
      WorkOrderAbandonedJob.perform(work_order.id)
    end

    context 'when the work order config contains a :email_upon_completion_follow_up_offset' do
      before do
        work_order.config = { customer_communications: { communications_enabled: true, email_upon_abandoned_follow_up_offset: 30.seconds } }
        work_order.save
      end

      it 'should enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :upon_abandoned_follow_up)
        WorkOrderAbandonedJob.perform(work_order.id)
      end
    end
  end
end
