require 'rails_helper'

describe CreateStripeSubscriptionJob do
  let(:stripe)          { StripeMock.create_test_helper }

  let(:company)         { FactoryGirl.create(:company) }
  let(:stripe_customer) { Stripe::Customer.create({email: company.user.email }) }

  before { allow_any_instance_of(Company).to receive(:stripe_customer) { stripe_customer } }
end
