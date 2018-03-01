require 'rails_helper'

describe CreateStripeCustomerJob do
  let(:company) { FactoryGirl.create(:company) }

  describe '.perform' do
    subject { CreateStripeCustomerJob.perform(Company.name, company.id) }

    it 'should use the stripe api to set the :stripe_customer_id on the company' do
      expect(company.reload.stripe_customer_id).to be_nil
      subject
      expect(company.reload.stripe_customer_id).to_not be_nil
    end
  end
end
