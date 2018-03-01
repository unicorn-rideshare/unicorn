require 'rails_helper'

describe Ability do
  let(:user)          { FactoryGirl.create(:user) }
  let(:ability_user)  { user }

  before { allow_any_instance_of(Ability).to receive(:resource) { resource.class } }

  context 'when there is no authenticated user' do
    let(:ability_user)  { nil }

    context User do
      let(:resource) { FactoryGirl.create(:user) }

      it_behaves_like 'ability', :create
    end

    context WorkOrder do
      let(:resource)  { work_order }
      subject(:ability) { Ability.new(ability_user, { :id => work_order.id.to_s }) }

      let(:work_order) { FactoryGirl.create(:work_order) }

      context 'when the work order customer communications configuration :exposes_status_publicly' do
        before do
          work_order.config = { customer_communications: { exposes_status_publicly: true } }
        end

        let(:resource)  { work_order }

        it { should be_able_to(:read, resource) }
        it { should_not be_able_to(:create, resource) }
        it { should_not be_able_to(:update, resource) }
        it { should_not be_able_to(:destroy, resource) }
      end

      context 'when the work order customer communications configuration :exposes_status_publicly is false' do
        before do
          work_order.config = { customer_communications: { exposes_status_publicly: false } }
        end

        it { should_not be_able_to(:read, resource) }
        it { should_not be_able_to(:create, resource) }
        it { should_not be_able_to(:update, resource) }
        it { should_not be_able_to(:destroy, resource) }
      end
    end
  end
end
