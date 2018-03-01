require 'rails_helper'

describe WorkOrderEmailJob do
  let(:work_order) { FactoryGirl.create(:work_order) }

  describe '.perform' do
    %w(morning_of_reminder reminder scheduled_confirmation).each do |mail_message|
      it "should send a :#{mail_message} email using the WorkOrderMailer" do
        expect(WorkOrderMailer).to receive("deliver_#{mail_message}".to_sym).with(work_order)
        WorkOrderEmailJob.perform(work_order.id, mail_message.to_sym)
      end
    end
  end
end
