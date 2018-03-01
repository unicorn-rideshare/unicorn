require 'rails_helper'

describe CompanyAdminAbility do
  before { skip }
  
  context 'when the user is an authenticated company administrator' do
    let(:user)          { FactoryGirl.create(:user) }
    let(:company)       { FactoryGirl.create(:company, user: user) }
    let(:dispatcher)    { FactoryGirl.create(:dispatcher, :with_user, company: company) }
    let(:provider)      { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:ability_user)  { user }

    context Checkin do
      context 'when the checkin belongs to a company provider' do
        let(:resource) { FactoryGirl.create(:checkin, locatable: provider.user) }
        it_behaves_like 'ability', :read
      end
    end

    context Company do
      let(:resource) { company }
      it_behaves_like 'ability', :read, :update, :destroy

      context Contact do
        let(:resource) { company.contact }
        it_behaves_like 'ability', :read, :update
      end
    end

    context Dispatcher do
      let(:resource) { dispatcher }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { dispatcher.contact }
        it_behaves_like 'ability', :read, :update
      end
    end

    context DispatcherOriginAssignment do
      let(:market)    { FactoryGirl.create(:market, company: company) }
      let(:resource)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Product do
      let(:resource) { FactoryGirl.create(:product, company: company) }
      it_behaves_like 'ability', :create, :destroy
    end

    context Customer do
      let(:customer)  { FactoryGirl.create(:customer, company: company) }
      let(:resource)  { customer }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Comment do
        context 'when the comment belongs to the user' do
          let(:resource)  { customer.comments.create(user_id: user.id) }
          it_behaves_like 'ability', :create, :read, :update, :destroy
        end

        context 'when the comment belongs to a company provider' do
          let(:resource)  { customer.comments.create(user_id: provider.user.id) }
          it_behaves_like 'ability', :create, :read, :update, :destroy
        end
      end

      context Contact do
        let(:resource)  { customer.contact }
        it_behaves_like 'ability', :read, :update
      end
    end

    context Market do
      let(:resource) { FactoryGirl.create(:market, company: company) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Origin do
      let(:resource) { FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: company)) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Provider do
      let(:resource) { provider }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { provider.contact }
        it_behaves_like 'ability', :read, :update
      end
    end

    context ProviderOriginAssignment do
      let(:market)    { FactoryGirl.create(:market, company: company) }
      let(:resource)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Route do
      let(:market)                        { FactoryGirl.create(:market, company: company) }
      let(:origin)                        { FactoryGirl.create(:origin, market: market) }
      let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: origin, start_date: Date.today, end_date: Date.today) }
      let(:provider_origin_assignment)    { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: origin, start_date: Date.today, end_date: Date.today) }
      let(:route)                         { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment) }
      let(:resource)                      { route }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context RouteLeg do
        let(:route_leg) { FactoryGirl.create(:route_leg, route: route) }
        let(:resource)  { route_leg }
        it_behaves_like 'ability', :create, :read, :update, :destroy
      end
    end

    context WorkOrder do
      let(:work_order)  { FactoryGirl.create(:work_order, company: company) }
      let(:resource)    { work_order }
      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Attachment do
        let(:attachment)  {  FactoryGirl.create(:attachment, attachable: work_order) }
        let(:resource)    { attachment }
        it_behaves_like 'ability', :create, :read, :update, :destroy

        context Comment do
          context 'when the comment belongs to the user' do
            let(:resource)  { attachment.comments.create(user_id: user.id) }
            it_behaves_like 'ability', :create, :read, :update, :destroy
          end

          context 'when the comment belongs to a company provider' do
            let(:resource)  { attachment.comments.create(user_id: provider.user.id) }
            it_behaves_like 'ability', :create, :read, :update, :destroy
          end
        end
      end

      context Comment do
        context 'when the comment belongs to the user' do
          let(:resource)  { work_order.comments.create(user_id: user.id) }
          it_behaves_like 'ability', :create, :read, :update, :destroy
        end

        context 'when the comment belongs to a company provider' do
          let(:resource)  { work_order.comments.create(user_id: provider.user.id) }
          it_behaves_like 'ability', :create, :read, :update, :destroy
        end
      end
    end
  end
end
