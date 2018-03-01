require 'rails_helper'

describe CompanyAbility do
  before { allow_any_instance_of(Ability).to receive(:resource) { resource.class } }

  context 'when the company is authenticated via the api' do
    let(:company)         { FactoryGirl.create(:company) }
    let(:customer)        { FactoryGirl.create(:customer, company: company) }
    let(:dispatcher)      { FactoryGirl.create(:dispatcher, :with_user, company: company) }
    let(:provider)        { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:market)          { FactoryGirl.create(:market, company: company) }
    let(:origin)          { FactoryGirl.create(:origin, market: market) }
    let(:ability_user)    { company }

    context Company do
      let(:resource)  { company }
      it_behaves_like 'ability', :read, :update

      context Contact do
        let(:resource) { company.contact }
        it_behaves_like 'ability', :read, :update
      end
    end

    context Customer do
      let(:resource)  { customer }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { customer.contact }
        it_behaves_like 'ability', :create, :read, :update, :destroy
      end
    end

    context Dispatcher do
      let(:resource) { dispatcher }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { dispatcher.contact }
        it_behaves_like 'ability', :create, :read, :update, :destroy
      end
    end

    context DispatcherOriginAssignment do
      let(:resource)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: origin, start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Market do
      let(:resource) { market }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Origin do
      let(:resource) { origin }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Product do
      let(:resource) { FactoryGirl.create(:product, company: company) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Provider do
      let(:resource) { provider }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { provider.contact }
        it_behaves_like 'ability', :create, :read, :update, :destroy
      end
    end

    context ProviderOriginAssignment do
      let(:resource)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: origin, start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Route do
      let(:route)     { FactoryGirl.create(:route) }
      let(:resource)  { route }
    end

    context WorkOrder do
      let(:work_order)  { FactoryGirl.create(:work_order, company: company) }
      let(:resource)    { work_order }

      it_behaves_like 'ability', :create, :read, :update, :destroy
    end
  end
end
