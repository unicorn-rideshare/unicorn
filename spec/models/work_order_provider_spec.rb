require 'rails_helper'

describe WorkOrderProvider do


  it { should belong_to(:provider) }
  it { should validate_presence_of(:provider) }

  it { should belong_to(:work_order) }
  it { should validate_presence_of(:work_order) }

  describe '#valid?' do
    let(:work_order) { FactoryGirl.create(:work_order, :with_provider) }
    let(:work_order_provider) { work_order.work_order_providers.first }

    it 'should not allow the company to change' do
      new_provider = FactoryGirl.create(:provider)
      work_order_provider.update_attributes(provider: new_provider) && true
      expect(work_order_provider.errors[:provider_id]).to include("can't be changed")
    end

    it 'should not allow the user to change' do
      new_work_order = FactoryGirl.create(:work_order)
      work_order_provider.update_attributes(work_order: new_work_order) && true
      expect(work_order_provider.errors[:work_order_id]).to include("can't be changed")
    end

    it 'should not associate another companies providers' do
      our_work_order = FactoryGirl.create(:work_order)
      their_provider = FactoryGirl.create(:provider)
      work_order_provider = WorkOrderProvider.new(work_order: our_work_order, provider: their_provider)
      work_order_provider.valid?
      expect(work_order_provider.errors[:provider_id]).to include("doesn't match Work Order's Company")
    end

    context 'the provider was not specified' do
      it 'should not validate the providers company' do
        our_work_order = FactoryGirl.create(:work_order)
        work_order_provider = WorkOrderProvider.new(work_order: our_work_order, provider: nil)
        work_order_provider.valid?
        expect(work_order_provider.errors[:provider_id]).to_not include("doesn't match Work Order's Company")
      end
    end

    context 'the work order was not specified' do
      it 'should not validate the providers company' do
        their_provider = FactoryGirl.create(:provider)
        work_order_provider = WorkOrderProvider.new(work_order: nil, provider: their_provider)
        work_order_provider.valid?
        expect(work_order_provider.errors[:provider_id]).to_not include("doesn't match Work Order's Company")
      end
    end
  end
end
