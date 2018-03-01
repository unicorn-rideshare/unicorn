require 'rails_helper'

describe CreateStripeCreditCardJob do
  let(:stripe)          { StripeMock.create_test_helper }

  let(:company)         { FactoryGirl.create(:company) }
  let(:stripe_customer) { Stripe::Customer.create({email: company.user.email }) }

  before do
    allow_any_instance_of(Company).to receive(:stripe_customer) { stripe_customer }
    allow(Resque).to receive(:enqueue).with(anything, anything)
    allow(Resque).to receive(:enqueue).with(DestroyStripeCreditCardJob, anything, anything, anything)
  end

  describe '.perform' do
    subject { CreateStripeCreditCardJob.perform(Company.name, company.id, stripe.generate_card_token) }

    it 'should use the stripe api to create a card and set the :stripe_credit_card_id on the company' do
      expect(company.reload.stripe_credit_card_id).to be_nil
      subject
      expect(company.reload.stripe_credit_card_id).to_not be_nil
    end

    context 'when no previous :stripe_credit_card_id was set' do
      it 'should not enqueue a DestroyStripeCreditCardJob' do
        expect(Resque).to_not receive(:enqueue).with(DestroyStripeCreditCardJob, anything)
        subject
      end
    end

    context 'when a previous :stripe_credit_card_id was set' do
      before  { company.update_attribute(:stripe_credit_card_id, 'old-stripe-card-id') }

      it 'should enqueue a DestroyStripeCreditCardJob to ensure the old :stripe_credit_card_id is deleted from the stripe customer account' do
        expect(Resque).to receive(:enqueue).with(DestroyStripeCreditCardJob, Company.name, company.id, 'old-stripe-card-id')
        subject
      end
    end
  end
end
