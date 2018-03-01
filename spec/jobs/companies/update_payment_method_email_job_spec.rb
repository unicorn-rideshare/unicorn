require 'rails_helper'

describe UpdatePaymentMethodEmailJob do
  let(:company) { FactoryGirl.create(:company) }

  describe '.perform' do
    subject { UpdatePaymentMethodEmailJob.perform(company.id) }

  end
end
