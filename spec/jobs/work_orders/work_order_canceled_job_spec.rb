require 'rails_helper'

describe WorkOrderCanceledJob do
  let(:work_order)  { FactoryGirl.create(:work_order, :canceled) }

  describe '.perform' do
    before  { expect(work_order.canceled_at).not_to be_nil }
    subject { WorkOrderCanceledJob.perform(work_order.id) }
  end
end
