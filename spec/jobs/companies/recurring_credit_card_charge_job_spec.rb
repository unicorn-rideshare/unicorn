require 'rails_helper'

describe RecurringCreditCardChargeJob do
  let(:stripe)          { StripeMock.create_test_helper }
  let(:company)         { FactoryGirl.create(:company, stripe_customer_id: 'stripe_cust_id') }
  let(:stripe_customer_without_card) { Stripe::Customer.create({email: company.user.email }) }
  let(:stripe_customer_with_card) { Stripe::Customer.create({email: company.user.email, source: stripe.generate_card_token }) }

  before { allow(Resque).to receive(:enqueue).with(anything, anything) }
  before { allow(Resque).to receive(:enqueue).with(anything, anything) }

  describe '.perform' do
    subject { RecurringCreditCardChargeJob.perform(company.id) }

    context 'when company#stripe_customer returns a nil stripe customer instance' do
      before { allow(Stripe::Customer).to receive(:retrieve).with('stripe_cust_id') { nil } }

      it 'should not attempt to charge the customer' do
        expect(Stripe::Charge).to_not receive(:create).with(anything)
        subject
      end
    end

    context 'when company#stripe_customer returns a valid stripe customer instance without a credit card on file' do
      before { allow(Stripe::Customer).to receive(:retrieve).with('stripe_cust_id') { stripe_customer_without_card } }

      context 'when the balance due is 0' do
        before { allow_any_instance_of(Company).to receive(:account_balance) { 0.00 } }

        it 'should not attempt to charge the customer' do
          expect(Stripe::Charge).to_not receive(:create).with(anything)
          subject
        end
      end

      context 'when the balance due is greater than 0' do
        before { allow_any_instance_of(Company).to receive(:account_balance) { 19.95 } }

        it 'should not use the stripe api to charge the customer on the company' do
          expect(Stripe::Charge).to_not receive(:create).with(anything)
          subject
        end

        it 'should enqueue an UpdatePaymentMethodEmailJob' do
          expect(Resque).to receive(:enqueue).with(UpdatePaymentMethodEmailJob, company.id)
          subject
        end
      end
    end

    context 'when company#stripe_customer returns a valid stripe customer instance with a credit card on file' do
      before { allow(Stripe::Customer).to receive(:retrieve).with('stripe_cust_id') { stripe_customer_with_card } }

      context 'when the balance due is 0' do
        before { allow_any_instance_of(Company).to receive(:account_balance) { 0.00 } }

        it 'should not attempt to charge the customer' do
          expect(Stripe::Charge).to_not receive(:create).with(anything)
          subject
        end
      end

      context 'when the balance due is greater than 0' do
        before { allow_any_instance_of(Company).to receive(:account_balance) { 19.95 } }

        it 'should use the stripe api to charge the customer on the company' do
          expect(Stripe::Charge).to receive(:create).with(amount: 1995,
                                                          currency: 'usd',
                                                          customer: 'stripe_cust_id',
                                                          description: "Charging #{company.name} $19.95")
          subject
        end
      end
    end
  end
end
