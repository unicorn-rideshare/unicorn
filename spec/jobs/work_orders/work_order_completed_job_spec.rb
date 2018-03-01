require 'rails_helper'

describe WorkOrderCompletedJob do
  let(:work_order)  { FactoryGirl.create(:work_order, ended_at: DateTime.now) }

  describe '.perform' do
    before do
      work_order.config = { customer_communications: { communications_enabled: true } }
      work_order.save
      
      expect(work_order.ended_at).not_to be_nil
    end

    context 'when the work order has rejected items' do
      before do
        product = FactoryGirl.create(:product, company: work_order.company)
        work_order.items_ordered << product
        work_order.items_rejected << product
      end

      it 'should enqueue a WorkOrderEmailJob to notify customer service' do
        expect(Resque).to receive(:enqueue).with(WorkOrderEmailJob, work_order.id, :customer_service_notification)
        WorkOrderCompletedJob.perform(work_order.id)
      end
    end

    context 'when the work order does not have rejected items' do
      it 'should not enqueue a WorkOrderEmailJob to notify customer service' do
        expect(Resque).not_to receive(:enqueue).with(WorkOrderEmailJob, work_order.id, :customer_service_notification)
        WorkOrderCompletedJob.perform(work_order.id)
      end
    end

    context 'when the work order config contains a :email_upon_completion_follow_up_offset' do
      before do
        work_order.config = { customer_communications: { communications_enabled: true, email_upon_completion_follow_up_offset: 30.seconds } }
        work_order.save
      end

      it 'should enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :upon_completion_follow_up)
        WorkOrderCompletedJob.perform(work_order.id)
      end
    end
  end
end
