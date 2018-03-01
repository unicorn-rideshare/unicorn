require 'rails_helper'

describe ProviderAbility do
  before { allow_any_instance_of(Ability).to receive(:resource) { resource.class } }

  context 'when the user is authenticated as a provider' do
    let(:company)             { FactoryGirl.create(:company) }
    let(:provider)            { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:provider_user)       { provider.user }
    let(:other_provider)      { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:other_provider_user) { other_provider.user }
    let(:ability_user)        { provider.user }

    context Checkin do
      context 'when the checkin belongs to another company provider' do
        let(:resource) { FactoryGirl.create(:checkin, locatable: other_provider.user) }
        it_behaves_like 'ability', :read
      end
    end

    context Company do
      let(:resource) { company }
      it_behaves_like 'ability', :read

      context Contact do
        let(:resource) { company.contact }
        it_behaves_like 'ability', :read
      end
    end

    context Customer do
      let(:customer)  { FactoryGirl.create(:customer, company: company) }
      let(:resource)  { customer }
      it_behaves_like 'ability', :read

      # context Comment do
      #   context 'when the comment belongs to the user' do
      #     let(:resource)  { customer.comments.create(user_id: provider.user.id) }
      #     it_behaves_like 'ability', :create, :read, :update, :destroy
      #   end

      #   context 'when the comment belongs to another company provider' do
      #     let(:resource)  { customer.comments.create(user_id: other_provider.user.id) }
      #     it_behaves_like 'ability', :read
      #   end
      # end

      context Contact do
        let(:resource)  { customer.contact }
        it_behaves_like 'ability', :read
      end
    end

    context Provider do
      let(:resource) { provider }
      it_behaves_like 'ability', :read

      context Contact do
        let(:resource)  { provider.contact }
        it_behaves_like 'ability', :read, :update

        context 'when the contact belongs to another company provider' do
          let(:resource)  { other_provider.contact }
          it_behaves_like 'ability', :read
        end
      end
    end

    context Route do
      let(:market)                      { FactoryGirl.create(:market, company: company) }
      let(:provider_origin_assignment)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      let(:route)                       { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment) }
      let(:resource)                    { route }

      context 'when the service provider is assigned to the route' do
        it_behaves_like 'ability', :read, :update

        context RouteLeg do
          let(:route_leg) { FactoryGirl.create(:route_leg, route: route) }
          let(:resource)  { route_leg }
          it_behaves_like 'ability', :read, :update
        end
      end

      context 'when the service provider is not assigned to the route' do
        subject(:ability) { Ability.new(other_provider.user) }
        let(:resource)    { route }

        it { should_not be_able_to(:read, resource) }
        it { should_not be_able_to(:create, resource) }
        it { should_not be_able_to(:update, resource) }
        it { should_not be_able_to(:delete, resource) }

        context RouteLeg do
          let(:route_leg) { FactoryGirl.create(:route_leg, route: route) }
          let(:resource)  { route_leg }

          it { should_not be_able_to(:read, resource) }
          it { should_not be_able_to(:create, resource) }
          it { should_not be_able_to(:update, resource) }
          it { should_not be_able_to(:delete, resource) }
        end
      end
    end

    context WorkOrder do
      let(:work_order)  { FactoryGirl.create(:work_order, company: company) }
      let(:resource)    { work_order }

      context 'when the user is not a service provider on the work order' do

      end

      context 'when the user is a service provider on the work order' do
        before { work_order.work_order_providers_attributes = [ { provider_id: provider.id } ] }
        it_behaves_like 'ability', :read, :update

        context Attachment do
          let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: provider.user) }
          let(:resource)    { attachment }
          # it_behaves_like 'ability', :create, :read, :update, :destroy
          #
          # context 'when the attachment belongs to another company provider' do
          #   let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: other_provider.user) }
          #   it_behaves_like 'ability', :read
          # end

          # context Comment do
          #   context 'when the comment belongs to the user' do
          #     let(:resource)  { attachment.comments.create(user_id: provider.user.id) }
          #     it_behaves_like 'ability', :create, :read, :update, :destroy
          #   end

          #   context 'when the comment belongs to another company provider' do
          #     let(:resource)  { attachment.comments.create(user_id: other_provider.user.id) }
          #     it_behaves_like 'ability', :read
          #   end
          # end
        end

        # context Comment do
        #   context 'when the comment belongs to the user' do
        #     let(:resource)  { work_order.comments.create(user_id: provider.user.id) }
        #     it_behaves_like 'ability', :create, :read, :update, :destroy
        #   end

        #   context 'when the comment belongs to another company provider' do
        #     let(:resource)  { work_order.comments.create(user_id: other_provider.user.id) }
        #     it_behaves_like 'ability', :read
        #   end
        # end
      end
    end
  end
end
