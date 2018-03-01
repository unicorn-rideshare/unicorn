require 'rails_helper'

describe DestroyStripeCreditCardJob do
  let(:stripe)          { StripeMock.create_test_helper }

  let(:company)         { FactoryGirl.create(:company) }
  let(:stripe_customer) { Stripe::Customer.create({email: company.user.email, source: stripe.generate_card_token }) }
  let(:stripe_card)     { stripe_customer.sources.first }

  before do
    allow_any_instance_of(Company).to receive(:stripe_customer) { stripe_customer }
  end

  describe '.perform' do
    subject { DestroyStripeCreditCardJob.perform(Company.name, company.id, stripe_customer.sources.first.id) }

    it 'should use the stripe api to destroy the stripe credit card' do
      expect_any_instance_of(Stripe::Card).to receive(:delete).once
      subject
    end
  end
end
