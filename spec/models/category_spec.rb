require 'rails_helper'

describe Category do
  let(:category) { FactoryGirl.create(:category) }



  it { should have_many(:tasks) }
  it { should have_many(:work_orders) }

  it { should have_and_belong_to_many(:providers) }

  it { should validate_presence_of(:name) }

  describe '#valid?' do
    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      category.update_attributes(company: new_company) && true
      expect(category.errors[:company_id]).to include("can't be changed")
    end
  end
end
