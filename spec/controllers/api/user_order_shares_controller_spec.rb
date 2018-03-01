require 'rails_helper'

describe Api::UserOrderSharesController, api: true do
  let(:user_order_share)  { FactoryGirl.create(:user_order_share, user: user) }

  context 'when the user is not logged in' do
    context 'when the user attempts to create a new user order share' do
      let(:params) { { fb_user_id: 'abc123', work_order_id: FactoryGirl.create(:work_order).id } }

      subject { post :create, params }

      it 'should create the new user order share' do
        expect { subject }.to change(UserOrderShare, :count).by(1)
      end

      it 'should set the given :fb_user_id on the share' do
        subject
        expect(UserOrderShare.first.fb_user_id).to eq('abc123')
      end

      it 'should set the given :work_order_id on the share' do
        subject
        expect(UserOrderShare.first.work_order_id).to eq(WorkOrder.first.id)
      end
    end
  end
end
