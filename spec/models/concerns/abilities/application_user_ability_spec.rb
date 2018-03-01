require 'rails_helper'

describe ApplicationUserAbility do
  let(:user)          { FactoryGirl.create(:user) }
  let(:ability_user)  { user }

  before { allow_any_instance_of(Ability).to receive(:resource) { resource.class } }

  context 'when there is an authenticated user' do
    context Checkin do
      let(:resource) { FactoryGirl.create(:checkin, locatable: user) }
      it_behaves_like 'ability', :create, :read, :destroy
    end

    context Company do
      let(:resource) { FactoryGirl.create(:company, user: user) }
      it_behaves_like 'ability', :read, :update
    end

    context 'when the user is a third-party consumer' do
      context Provider do
        let(:provider)  { FactoryGirl.create(:provider) }
        let(:resource)  { provider }

        context 'third-party user' do
          let(:ability_user) { FactoryGirl.create(:user) }

          context 'provider is not configured to expose availability publicly' do
            let(:resource) { FactoryGirl.create(:provider) }

            subject { Ability.new(ability_user) }

            it { should_not be_able_to(:index, resource) }
            it { should_not be_able_to(:read, resource) }

            it { should_not be_able_to(:create, resource) }
            it { should_not be_able_to(:update, resource) }
            it { should_not be_able_to(:destroy, resource) }
          end

          context 'provider is configured to expose availability publicly' do
            let(:resource) { FactoryGirl.create(:provider, publicly_available: true) }

            subject { Ability.new(ability_user) }

            it { should be_able_to(:index, resource) }
            it { should be_able_to(:read, resource) }

            it { should_not be_able_to(:create, resource) }
            it { should_not be_able_to(:update, resource) }
            it { should_not be_able_to(:destroy, resource) }
          end
        end
      end
    end
  end
end
