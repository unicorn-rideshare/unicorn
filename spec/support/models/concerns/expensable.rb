shared_examples 'expensable' do
  it { should have_many(:expenses) }

  describe 'destroying the expensable' do
    let(:expense)     { FactoryGirl.create(:expense) }
    let(:expensable)  { expense.expensable }

    before { expect(expensable.reload.expenses.size).to eq(1) }

    subject { expensable.destroy }

    it 'should destroy all of the expenses which belong to the destroyed expensable' do
      subject
      expect(expensable.expenses.size).to eq(0)
    end
  end
end
