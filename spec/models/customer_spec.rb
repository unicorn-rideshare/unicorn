require 'rails_helper'

describe Customer do
  let(:user)     { FactoryGirl.create(:user) }
  let(:customer) { FactoryGirl.create(:customer, user: user) }

  it_behaves_like 'commentable'
  it_behaves_like 'contactable' do
    let(:contactable) { customer }
  end

  it { should belong_to(:company) }
  it { should validate_presence_of(:company) }

  it { should belong_to(:user) }

  it { should have_many(:jobs) }

  it { should have_many(:work_orders) }

  describe '#valid?' do
    it 'should validate uniqueness of the user id, scoped to company id' do
      new_customer = FactoryGirl.create(:customer, user: user)
      expect(new_customer.valid?).to eq(true)

      new_customer = FactoryGirl.build(:customer, user: user, company: customer.company)
      expect(new_customer.valid?).to eq(false)
    end

    it 'should allow a nil user id' do
      new_customer = FactoryGirl.create(:customer, user: nil)
      expect(new_customer.valid?).to eq(true)
    end

    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      customer.update_attributes(company: new_company) && true
      expect(customer.errors[:company_id]).to include("can't be changed")
    end

    it 'should not allow the user to change' do
      new_user = FactoryGirl.create(:user)
      customer.update_attributes(user: new_user) && true
      expect(customer.errors[:user_id]).to include("can't be changed")
    end
  end

  describe '#communications_config' do
    let(:company)  { FactoryGirl.create(:company) }
    let(:customer) { FactoryGirl.create(:customer, company: company) }

    context 'when the customer settings have not been modified from default values' do
      before do
        company.config = { customer_communications: { exposes_status_publicly: true } }
        company.save
      end

      it 'should return the company communications config' do
        expect(customer.communications_config[:exposes_status_publicly]).to eq(true)
      end
    end

    context 'when the customer settings have been modified from default values' do
      before do
        customer.config =  { customer_communications: { rating_request_dial_offset: 1000 } }
        customer.save
      end

      it 'should return the customer communications config' do
        expect(customer.communications_config[:rating_request_dial_offset]).to eq(1000)
      end
    end
  end
end
