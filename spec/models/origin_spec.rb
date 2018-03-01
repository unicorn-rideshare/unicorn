require 'rails_helper'

describe Origin do
  let(:market)  { FactoryGirl.create(:market) }
  let(:origin)  { FactoryGirl.create(:origin, market: market) }

  it_behaves_like 'contactable' do
    let(:contactable) { origin }
  end



  it { should belong_to(:market) }
  it { should validate_presence_of(:market) }

  it { should have_many(:provider_origin_assignments) }
  it { should have_many(:providers).through(:provider_origin_assignments) }

  it { should have_many(:work_orders) }

  describe '#available_dispatcher_origin_assignments' do
    let(:start_date)                  { Date.today }

    before do
      FactoryGirl.create(:dispatcher_origin_assignment, start_date: start_date, end_date: start_date, scheduled_start_at: start_date, origin: origin)
      FactoryGirl.create(:dispatcher_origin_assignment, start_date: start_date + 1.day, end_date: start_date + 1.day, scheduled_start_at: start_date + 1.day, origin: origin)
      FactoryGirl.create(:dispatcher_origin_assignment, start_date: start_date + 2.days, end_date: start_date + 2.days, scheduled_start_at: start_date + 2.days, origin: origin)
    end

    context 'when there are no available dispatcher origin assignments' do
      before { DispatcherOriginAssignment.all.map { |doa| FactoryGirl.create(:route, dispatcher_origin_assignment: doa, date: doa.start_date, scheduled_start_at: doa.start_date) } }

      it 'should return an empty list' do
        expect(origin.available_dispatcher_origin_assignments(start_date)).to eq([])
      end
    end

    context 'when there are available dispatcher origin assignments' do
      let(:query_date) { start_date + 1.day }

      it 'should return the list of available dispatchers' do
        expect(origin.available_dispatcher_origin_assignments(query_date)).to eq([DispatcherOriginAssignment.unscoped.second])
      end
    end
  end

  describe '#available_provider_origin_assignments' do
    let(:start_date)                  { Date.today }

    before do
      FactoryGirl.create(:provider_origin_assignment, start_date: start_date, end_date: start_date, origin: origin)
      FactoryGirl.create(:provider_origin_assignment, start_date: start_date + 1.day, end_date: start_date + 1.day, origin: origin)
      FactoryGirl.create(:provider_origin_assignment, start_date: start_date + 2.days, end_date: start_date + 2.days, origin: origin)
    end

    context 'when there are no available provider origin assignments' do
      before { ProviderOriginAssignment.all.map { |poa| FactoryGirl.create(:route, provider_origin_assignment: poa, date: poa.start_date, scheduled_start_at: poa.start_date) } }
      
      it 'should return an empty list' do
        expect(origin.available_provider_origin_assignments(start_date)).to eq([])
      end
    end

    context 'when there are available provider origin assignments' do
      let(:query_date) { start_date + 1.day }

      it 'should return the list of available providers' do
        expect(origin.available_provider_origin_assignments(query_date)).to eq([ProviderOriginAssignment.unscoped.second])
      end
    end
  end
end
