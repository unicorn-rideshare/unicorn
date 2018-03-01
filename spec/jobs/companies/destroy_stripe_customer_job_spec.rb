require 'rails_helper'

describe DestroyStripeCustomerJob do
  let(:stripe)           { StripeMock.create_test_helper }
  let(:stripe_customer)  { Stripe::Customer.create({ email: 'test@example.com', source: stripe.generate_card_token }) }

  before do
    allow(Stripe::Customer).to receive(:retrieve).with('stripe-customer-id') { stripe_customer }
    allow(stripe_customer).to receive(:delete)
  end

  describe '.perform' do
    subject { DestroyStripeCustomerJob.perform('stripe-customer-id') }

    it 'should use the stripe api to destroy the stripe customer' do
      subject
      expect(stripe_customer).to have_received(:delete).once
    end
  end
end
