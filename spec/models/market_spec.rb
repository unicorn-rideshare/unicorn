require 'rails_helper'

describe Market do

  it { should belong_to(:company) }

  it { should validate_presence_of(:name) }

  it { should have_many(:origins) }

  describe '#valid?' do
    let(:market)  { FactoryGirl.create(:market) }

    it 'should not allow the company to change' do
      market.update_attributes(company: FactoryGirl.create(:company)) && true
      expect(market.errors[:company_id]).to include("can't be changed")
    end
  end
end
