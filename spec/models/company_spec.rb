require 'rails_helper'

describe Company do
  let(:company) { FactoryGirl.create(:company) }

  it_behaves_like 'authenticable'

  it_behaves_like 'contactable' do
    let(:contactable) { company }
  end

  it { should validate_presence_of(:name) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:user) }

  it { should have_many(:categories) }
  it { should have_many(:customers) }
  it { should have_many(:dispatchers) }
  it { should have_many(:jobs) }
  it { should have_many(:markets) }
  it { should have_many(:products) }
  it { should have_many(:providers) }
  it { should have_many(:routes) }
  it { should have_many(:tasks) }
  it { should have_many(:work_orders) }

  describe '#valid?' do
    it 'should not allow the user to change' do
      new_user = FactoryGirl.create(:user)
      company.update_attributes(user: new_user) && true
      expect(company.errors[:user_id]).to include("can't be changed")
    end
  end

  describe '#destroy' do
    before do
      allow(Resque).to receive(:remove_schedule).with("RecurringCreditCardChargeJob_Company_#{company.id}")
      allow(Resque).to receive(:set_schedule).with("RecurringCreditCardChargeJob_Company_#{company.id}", anything)
    end

    subject { company.destroy }

    it 'should remove the previously scheduled RecurringCreditCardChargeJob' do
      subject
      expect(Resque).to have_received(:remove_schedule).with("RecurringCreditCardChargeJob_Company_#{company.id}")
    end
  end

  describe '#save' do
    let(:user)    { FactoryGirl.create(:user) }
    let(:company) { FactoryGirl.build(:company, user: user) }

    context 'when the company is created for the first time' do
      before do
        allow(Resque).to receive(:enqueue).with(anything, anything)
        allow(Resque).to receive(:enqueue).with(anything, anything, anything)
        allow(Resque).to receive(:set_schedule).with(anything, anything)
      end

      subject { company.save }

      it 'should give the creating user admin permissions on the company' do
        expect { subject }.to change { user.roles.count }.by(1)
        expect(user.has_role?(:admin, company)).to eq(true)
      end

      # FIXME-- this test behaves strangely
      xit 'should enqueue a CreateStripeCustomerJob to ensure the :stripe_customer_id is set' do
        subject
        expect(Resque).to have_received(:enqueue).with(CreateStripeCustomerJob, Company.name, anything)
      end

      it 'should enqueue a RecurringCreditCardChargeJob for the company' do
        subject
        expect(Resque).to have_received(:set_schedule).with("RecurringCreditCardChargeJob_Company_#{company.id}", { class: RecurringCreditCardChargeJob.name,
                                                                                                                    args: company.id,
                                                                                                                    every: ['30d', { first_in: 30.days }],
                                                                                                                    persist: true })
      end
    end

    describe '#apply_stripe_coupon_code' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { company.apply_stripe_coupon_code('stripe-coupon-code') }

      it 'should enqueue a ApplyStripeCouponCodeJob on behalf of the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(ApplyStripeCouponCodeJob, Company.name, company.id, 'stripe-coupon-code')
        subject
      end
    end

    describe '#create_stripe_credit_card' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { company.create_stripe_credit_card('stripe-card-id') }

      it 'should enqueue a CreateStripeCreditCardJob on behalf of the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(CreateStripeCreditCardJob, Company.name, company.id, 'stripe-card-id')
        subject
      end
    end

    describe '#destroy_stripe_credit_card' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { company.destroy_stripe_credit_card('stripe-card-id') }

      it 'should enqueue a DestroyStripeCreditCardJob on behalf of the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(DestroyStripeCreditCardJob, Company.name, company.id, 'stripe-card-id')
        subject
      end
    end

    describe '#create_stripe_subscription' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { company.create_stripe_subscription('stripe-subscription-id') }

      it 'should enqueue a CreateStripeSubscriptionJob on behalf of the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(CreateStripeSubscriptionJob, Company.name, company.id, 'stripe-subscription-id', nil)
        subject
      end
    end

    describe '#cancel_stripe_subscription' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { company.cancel_stripe_subscription('stripe-subscription-id') }

      it 'should enqueue a CancelStripeSubscriptionJob on behalf of the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(CancelStripeSubscriptionJob, Company.name, company.id, 'stripe-subscription-id')
        subject
      end
    end

    describe 'dispatchers' do
      context 'when a dispatcher was added to the company' do
        let(:dispatcher) { FactoryGirl.create(:dispatcher, :with_user, company: company) }

        before  { company.save }

        subject do
          company.dispatchers << dispatcher
          company.save
        end

        it 'should give the newly associated dispatcher user the :dispatcher role on the company' do
          #expect { subject }.to change { dispatcher.user.roles.count }.by(1)
          expect(dispatcher.user.has_role?(:dispatcher, company)).to eq(true)
        end
      end

      context 'when a dispatcher was removed from the company' do
        let(:dispatcher) { FactoryGirl.create(:dispatcher, :with_user, company: company) }

        before do
          company.dispatchers << dispatcher
          company.save
        end

        subject do
          company.dispatchers = []
          company.save
        end

        it 'should remove the :dispatcher role on the company from the dispatcher user' do
          expect { subject }.to change { dispatcher.user.roles.count }.by(-1)
          expect(dispatcher.user.has_role?(:dispatcher, company)).to eq(false)
        end
      end
    end

    describe 'providers' do
      context 'when a provider was added to the company' do
        let(:provider) { FactoryGirl.create(:provider, :with_user, company: company) }

        before  { company.save }

        subject do
          company.providers << provider
          company.save
        end

        it 'should give the newly associated provider user the :provider role on the company' do
          #expect { subject }.to change { provider.user.roles.count }.by(1)
          expect(provider.user.has_role?(:provider, company)).to eq(true)
        end
      end

      context 'when a provider was removed from the company' do
        let(:provider) { FactoryGirl.create(:provider, :with_user, company: company) }

        before do
          company.providers << provider
          company.save
        end

        subject do
          company.providers = []
          company.save
        end

        it 'should remove the :provider role on the company from the provider user' do
          expect { subject }.to change { provider.user.roles.count }.by(-1)
          expect(provider.user.has_role?(:provider, company)).to eq(false)
        end
      end
    end
  end

  describe '#has_card?' do
    let(:stripe)          { StripeMock.create_test_helper }
    let(:company)         { FactoryGirl.create(:company, stripe_customer_id: 'stripe_cust_id') }
    let(:stripe_customer_without_card) { Stripe::Customer.create({email: company.user.email }) }
    let(:stripe_customer_with_card) { Stripe::Customer.create({email: company.user.email, source: stripe.generate_card_token }) }

    subject { company.has_card? }

    context 'when the company does not have any cards on file' do
      before { allow(Stripe::Customer).to receive(:retrieve).with('stripe_cust_id') { stripe_customer_without_card } }

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the company has a card on file' do
      before { allow(Stripe::Customer).to receive(:retrieve).with('stripe_cust_id') { stripe_customer_with_card } }

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe '#facebook_app_id' do
    context 'when the company config contains a facebook app id' do
      let(:facebook_app_id) { 'asdf-qwerty' }

      before do
        company.config = { facebook_app_id: facebook_app_id }
        company.save
      end

      it 'should store the facebook app id' do
        expect(company.reload.facebook_app_id).to eq(facebook_app_id)
      end
    end
  end
end
