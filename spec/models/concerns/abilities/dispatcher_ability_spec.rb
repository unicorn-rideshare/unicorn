require 'rails_helper'

describe DispatcherAbility do
  before { allow_any_instance_of(Ability).to receive(:resource) { resource.class } }

  context 'when the user is an authenticated as a dispatcher' do
    let(:company)                       { FactoryGirl.create(:company) }
    let(:dispatcher)                    { FactoryGirl.create(:dispatcher, :with_user, company: company) }
    let(:provider)                      { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:origin)                        { FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: company)) }
    let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: origin, start_date: Date.today, end_date: Date.today) }
    let(:provider_origin_assignment)    { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: origin, start_date: Date.today, end_date: Date.today) }
    let(:other_dispatcher)              { FactoryGirl.create(:dispatcher, :with_user, company: company) }
    let(:other_dispatcher_user)         { other_dispatcher.user }
    let(:route)                         { FactoryGirl.create(:route) }
    let(:ability_user)                  { dispatcher.user }

    before do
      company.dispatchers << dispatcher
      company.providers << provider

      route = FactoryGirl.create(:route,
                                 provider_origin_assignment: provider_origin_assignment,
                                 dispatcher_origin_assignment: dispatcher_origin_assignment,
                                 date: Date.today)
    end

    context Checkin do
      context 'when the checkin belongs to a company provider' do
        let(:resource) { FactoryGirl.create(:checkin, locatable: provider.user) }
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
      #     let(:resource)  { customer.comments.create(user_id: dispatcher.user.id) }
      #     it_behaves_like 'ability', :create, :read, :update, :destroy
      #   end

      #   context 'when the comment belongs to another company dispatcher' do
      #     let(:resource)  { customer.comments.create(user_id: other_dispatcher.user.id) }
      #     it_behaves_like 'ability', :read
      #   end

      #   context 'when the comment belongs to a company provider' do
      #     let(:resource)  { customer.comments.create(user_id: provider.user.id) }
      #     it_behaves_like 'ability', :read
      #   end
      # end

      context Contact do
        let(:resource)  { customer.contact }
        it_behaves_like 'ability', :read
      end
    end

    context Dispatcher do
      let(:resource) { dispatcher }
      it_behaves_like 'ability', :read

      context Contact do
        let(:resource)  { dispatcher.contact }
        it_behaves_like 'ability', :read, :update

        context 'when the contact belongs to another company dispatcher' do
          let(:resource)  { other_dispatcher.contact }
          it_behaves_like 'ability', :read
        end

        context 'when the contact belongs to a company provider' do
          let(:resource)  { provider.contact }
          it_behaves_like 'ability', :read
        end
      end
    end

    context DispatcherOriginAssignment do
      let(:market)    { FactoryGirl.create(:market, company: company) }
      let(:resource)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Market do
      let(:resource) { FactoryGirl.create(:market, company: company) }
      it_behaves_like 'ability', :read
    end

    context Origin do
      let(:resource) { FactoryGirl.create(:origin, market: FactoryGirl.create(:market, company: company)) }
      it_behaves_like 'ability', :read
    end

    context Product do
      let(:resource) { FactoryGirl.create(:product, company: company) }
      it_behaves_like 'ability', :create, :read, :update
    end

    context Provider do
      let(:resource) { provider }

      it_behaves_like 'ability', :create, :read, :update, :destroy

      context Contact do
        let(:resource)  { provider.contact }
        it_behaves_like 'ability', :create, :read
      end
    end

    context ProviderOriginAssignment do
      let(:market)    { FactoryGirl.create(:market, company: company) }
      let(:resource)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      it_behaves_like 'ability', :create, :read, :update, :destroy
    end

    context Route do
      let(:market)                        { FactoryGirl.create(:market, company: company) }
      let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
      let(:route)                         { FactoryGirl.create(:route) }
      let(:resource)                      { route }

      context 'when the dispatcher is assigned to the route' do
        let(:route)                       { FactoryGirl.create(:route, dispatcher_origin_assignment: dispatcher_origin_assignment) }
        it_behaves_like 'ability', :read, :update

        context RouteLeg do
          let(:route_leg) { FactoryGirl.create(:route_leg, route: route) }
          let(:resource)  { route_leg }
          it_behaves_like 'ability', :read, :update
        end

        context WorkOrder do
          let(:market)                        { FactoryGirl.create(:market, company: company) }
          let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
          let(:route)                         { FactoryGirl.create(:route, dispatcher_origin_assignment: dispatcher_origin_assignment) }
          let(:resource)                      { route }
          let(:work_order)                    { FactoryGirl.create(:work_order, company: company) }
          let(:resource)                      { work_order }

          context 'when the user is not a dispatcher on the work order' do

          end

          context 'when the user is a dispatcher on the work order' do
            before { route.legs.create(work_order: work_order) }

            it_behaves_like 'ability', :read, :update

            # context Attachment do
            #   let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: dispatcher.user) }
            #   let(:resource)    { attachment }
            #   it_behaves_like 'ability', :create, :read, :update, :destroy

            #   context 'when the attachment belongs to another company dispatcher' do
            #     let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: other_dispatcher.user) }
            #     it_behaves_like 'ability', :read
            #   end

            #   context 'when the attachment belongs to a company provider' do
            #     let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: provider.user) }
            #     it_behaves_like 'ability', :read
            #   end

              # context Comment do
              #   context 'when the comment belongs to the user' do
              #     let(:resource)  { attachment.comments.create(user_id: dispatcher.user.id) }
              #     it_behaves_like 'ability', :create, :read, :update, :destroy
              #   end

              #   context 'when the comment belongs to another company dispatcher' do
              #     let(:resource)  { attachment.comments.create(user_id: other_dispatcher.user.id) }
              #     it_behaves_like 'ability', :read
              #   end

              #   context 'when the comment belongs to a company provider' do
              #     let(:resource)  { attachment.comments.create(user_id: provider.user.id) }
              #     it_behaves_like 'ability', :read
              #   end
              # end
            # end

            # context Comment do
            #   context 'when the comment belongs to the user' do
            #     let(:resource)  { work_order.comments.create(user_id: dispatcher.user.id) }
            #     it_behaves_like 'ability', :create, :read, :update, :destroy
            #   end

            #   context 'when the comment belongs to another company dispatcher' do
            #     let(:resource)  { work_order.comments.create(user_id: other_dispatcher.user.id) }
            #     it_behaves_like 'ability', :read
            #   end

            #   context 'when the comment belongs to a company provider' do
            #     let(:resource)  { work_order.comments.create(user_id: provider.user.id) }
            #     it_behaves_like 'ability', :read
            #   end
            # end
          end
        end
      end

      context 'when the dispatcher is not assigned to the route' do
        subject(:ability) { Ability.new(other_dispatcher.user) }
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
      context 'when the user is a dispatcher on the work order company' do
        let(:work_order)  { FactoryGirl.create(:work_order, company: company) }
        let(:resource)    { work_order }

        it_behaves_like 'ability', :create, :read, :update

        # context Attachment do
        #   let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: dispatcher.user) }
        #   let(:resource)    { attachment }
        #   it_behaves_like 'ability', :create, :read, :update, :destroy

        #   context 'when the attachment belongs to another company dispatcher' do
        #     let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: other_dispatcher.user) }
        #     it_behaves_like 'ability', :read
        #   end

        #   context 'when the attachment belongs to a company provider' do
        #     let(:attachment)  { FactoryGirl.create(:attachment, attachable: work_order, user: provider.user) }
        #     it_behaves_like 'ability', :read
        #   end

          # context Comment do
          #   context 'when the comment belongs to the user' do
          #     let(:resource)  { attachment.comments.create(user_id: dispatcher.user.id) }
          #     it_behaves_like 'ability', :create, :read, :update, :destroy
          #   end

          #   context 'when the comment belongs to another company dispatcher' do
          #     let(:resource)  { attachment.comments.create(user_id: other_dispatcher.user.id) }
          #     it_behaves_like 'ability', :read
          #   end

          #   context 'when the comment belongs to a company provider' do
          #     let(:resource)  { attachment.comments.create(user_id: provider.user.id) }
          #     it_behaves_like 'ability', :read
          #   end
          # end
        # end

        # context Comment do
        #   context 'when the comment belongs to the user' do
        #     let(:resource)  { work_order.comments.create(user_id: provider.user.id) }
        #     it_behaves_like 'ability', :create, :read, :update, :destroy
        #   end

        #   context 'when the comment belongs to another company dispatcher' do
        #     let(:resource)  { work_order.comments.create(user_id: other_dispatcher.user.id) }
        #     it_behaves_like 'ability', :read
        #   end

        #   context 'when the comment belongs to a company provider' do
        #     let(:resource)  { work_order.comments.create(user_id: provider.user.id) }
        #     it_behaves_like 'ability', :read
        #   end
        # end
      end
    end
  end
end
