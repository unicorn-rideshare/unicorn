require 'rails_helper'

describe Expense do
  let(:expense) { FactoryGirl.create(:expense) }

  it_behaves_like 'attachable'


  it { should belong_to(:expensable) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:user) }
  
  describe 'state machine' do
    it 'should initially set the expense status to :submitted' do
      expect(expense.status.to_sym).to eq(:submitted)
    end
  end
end
