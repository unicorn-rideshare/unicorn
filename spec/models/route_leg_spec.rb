require 'rails_helper'

describe RouteLeg do
  let(:company) { FactoryGirl.create(:company) }
  let(:date)    { Date.today }
  let(:route) { FactoryGirl.create(:route,
                                   provider_origin_assignment: FactoryGirl.create(:provider_origin_assignment, provider: FactoryGirl.create(:provider, company: company), start_date: date, end_date: date),
                                   dispatcher_origin_assignment: FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: FactoryGirl.create(:dispatcher, company: company), start_date: date, end_date: date),
                                   date: Date.today) }



  it { should belong_to(:route) }
  it { should have_one(:work_order) }
  it { should validate_presence_of(:work_order) }

  describe '#valid?' do
    describe 'changing the work order assigned to the leg' do
      let(:work_order)  { FactoryGirl.create(:work_order, :scheduled, company: route.provider_origin_assignment.provider.company) }
      let(:route_leg)   { route.legs.create(work_order: work_order) }

      context 'when the currently set work order status is awaiting_schedule' do
        it 'should return true' do
          route_leg.reload.work_order = FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company)
          expect(route_leg.valid?).to eq(true)
        end
      end

      context 'when the currently set work order status is scheduled' do
        it 'should return true' do
          route_leg.reload.work_order = FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company)
          expect(route_leg.valid?).to eq(true)
        end
      end

      context 'when the currently set work order is not scheduled' do
        before { work_order.route! }

        it 'should return false' do
          route_leg.work_order = work_order
          expect(route_leg.valid?).to eq(false)
        end
      end
    end
  end

  describe '#can_start?' do
    let(:route_leg) { route.legs.create(work_order: work_order) }

    context 'when the associated work order status is :awaiting_schedule' do
      let(:work_order)  { FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_start?).to eq(false)
      end
    end

    context 'when the associated work order status is :scheduled' do
      let(:work_order)  { FactoryGirl.create(:work_order, :scheduled, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_start?).to eq(true)
      end
    end

    context 'when the associated work order status is :in_progress' do
      let(:work_order)  { FactoryGirl.create(:work_order, :in_progress, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_start?).to eq(false)
      end
    end
  end

  describe '#can_schedule?' do
    let(:route_leg) { route.legs.create(work_order: work_order) }

    context 'when the associated work order status is :awaiting_schedule' do
      let(:work_order)  { FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_schedule?).to eq(true)
      end
    end

    context 'when the associated work order status is :scheduled' do
      let(:work_order)  { FactoryGirl.create(:work_order, :scheduled, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_schedule?).to eq(false)
      end
    end

    context 'when the associated work order status is :in_progress' do
      let(:work_order)  { FactoryGirl.create(:work_order, :in_progress, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_schedule?).to eq(false)
      end
    end

    context 'when the associated work order status is :abandoned' do
      let(:work_order)  { FactoryGirl.create(:work_order, :abandoned, company: route.provider_origin_assignment.provider.company) }

      it 'should return true' do
        expect(route_leg.can_schedule?).to eq(true)
      end
    end
  end
end
