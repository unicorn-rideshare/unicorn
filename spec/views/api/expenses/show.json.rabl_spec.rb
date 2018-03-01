require 'rails_helper'

describe 'api/expenses/show' do
  let(:expense) { FactoryGirl.create(:expense, incurred_at: DateTime.now - 15.minutes, amount: 15.99, description: 'hardware') }

  it 'should render expense' do
    @expense = expense
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => expense.id,
                                        'user_id' => expense.user_id,
                                        'expensable_type' => expense.expensable_type.underscore,
                                        'expensable_id' => expense.expensable_id,
                                        'amount' => 15.99,
                                        'description' => 'hardware',
                                        'created_at' => expense.created_at.iso8601,
                                        'updated_at' => expense.updated_at.iso8601,
                                        'incurred_at' => expense.incurred_at.iso8601,
                                        'attachments' => [],
                                    )
  end
end
