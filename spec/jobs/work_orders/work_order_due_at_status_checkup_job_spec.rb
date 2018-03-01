require 'rails_helper'

describe WorkOrderDueAtStatusCheckupJob do
  let(:work_order) { FactoryGirl.create(:work_order) }

  describe '.perform' do
    context 'when the work order status is :delayed' do
      let(:work_order) { FactoryGirl.create(:work_order, :delayed) }


      it 'should mark the work order as abandoned' do
        WorkOrderDueAtStatusCheckupJob.perform(work_order.id)
        expect(work_order.reload.status).to eq('abandoned')
      end
    end
  end
end
