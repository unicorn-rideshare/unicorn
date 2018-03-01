require 'rails_helper'

describe WorkOrderRescheduledJob do
  let(:work_order) { FactoryGirl.create(:work_order, scheduled_start_at: DateTime.now + 5.days) }

  before do
    work_order.config = { customer_communications: { exposes_status_publicly: nil } }
    work_order.save
  end

  describe '.perform' do
    before do
      allow(Resque).to receive(:enqueue_at)
      allow(Resque).to receive(:remove_delayed)
    end

    it 'should remove any WorkOrderEmailJob instances already enqueued for :scheduled_confirmation emails' do
      expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :scheduled_confirmation)
      WorkOrderRescheduledJob.perform(work_order.id)
    end

    it 'should remove any WorkOrderEmailJob instances already enqueued for :reminder emails' do
      expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :reminder)
      WorkOrderRescheduledJob.perform(work_order.id)
    end

    it 'should remove any WorkOrderEmailJob instances already enqueued for :morning_of_reminder emails' do
      expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :morning_of_reminder)
      WorkOrderRescheduledJob.perform(work_order.id)
    end

    it 'should remove any WorkOrderStartedStatusCheckupJob instances already enqueued' do
      expect(Resque).to receive(:remove_delayed).with(WorkOrderStartedStatusCheckupJob, work_order.id)
      WorkOrderRescheduledJob.perform(work_order.id)
    end

    context 'when the work order :scheduled_start_at is not nil' do
      it 'should enqueue a WorkOrderStartedStatusCheckupJob using the work order configuration' do
        expect(Resque).to receive(:enqueue_at).with(anything, WorkOrderStartedStatusCheckupJob, work_order.id)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order :scheduled_start_at is nil' do
      let(:work_order) { FactoryGirl.create(:work_order, scheduled_start_at: nil) }

      it 'should not enqueue a WorkOrderStartedStatusCheckupJob' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderStartedStatusCheckupJob, work_order.id)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order config contains a :email_morning_of_reminder_offset' do
      before do
        work_order.config = { customer_communications: { email_morning_of_reminder_offset: 1.day.seconds * -1 } }
        work_order.save
      end

      it 'should enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :reminder)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order, customer, and company config does not contain a :email_morning_of_reminder_offset' do
      before do
        [work_order, work_order.customer, work_order.company].each do |obj|
          obj.config = { customer_communications: { email_morning_of_reminder_offset: nil } }
          obj.save
        end
      end

      it 'should not enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :reminder)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order config contains a :email_reminder_offset' do
      before do
        work_order.config = { customer_communications: { email_reminder_offset: 1.day.seconds * -1 } }
        work_order.save
      end

      it 'should enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :reminder)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order, customer, and company config does not contain a :email_reminder_offset' do
      before do
        [work_order, work_order.customer, work_order.company].each do |obj|
          obj.config = { customer_communications: { email_reminder_offset: nil } }
          obj.save
        end
      end

      it 'should not enqueue a WorkOrderEmailJob using the work order configuration' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :reminder)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order config contains a :email_scheduled_confirmation_offset' do
      before do
        work_order.config = { customer_communications: { email_scheduled_confirmation_offset: 2.days.seconds * -1 } }
        work_order.save
      end

      it 'should enqueue a WorkOrderEmailJob per the work order configuration' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :reminder)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end

    context 'when the work order config does not contain a :email_scheduled_confirmation_offset' do
      before do
        [work_order, work_order.customer, work_order.company].each do |obj|
          obj.config = { customer_communications: { email_scheduled_confirmation_offset: nil } }
          obj.save
        end
      end

      it 'should not enqueue a WorkOrderEmailJob' do
        expect(Resque).not_to receive(:enqueue_at).with(anything, WorkOrderEmailJob, work_order.id, :scheduled_confirmation)
        WorkOrderRescheduledJob.perform(work_order.id)
      end
    end
  end
end
