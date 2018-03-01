require 'rails_helper'

describe 'api/jobs/show' do
  let(:user)  { FactoryGirl.create(:user) }
  let(:job) { FactoryGirl.create(:job, name: 'Cardinal Glass Plant') }

  it 'should render job' do
    @job = job
    customer = job.customer
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => job.id,
                                        'company_id' => job.company_id,
                                        'customer_id' => customer.id,
                                        'name' => 'Cardinal Glass Plant',
                                        'type' => job.type,
                                        'status' => 'configuring',
                                        'work_orders_count' => 0,
                                        'quoted_price_per_sq_ft' => nil,
                                    )
  end
end
