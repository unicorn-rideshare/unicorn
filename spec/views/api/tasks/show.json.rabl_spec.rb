require 'rails_helper'

describe 'api/tasks/show' do
  let(:user)  { FactoryGirl.create(:user) }
  let(:task)  { FactoryGirl.create(:task, name: 'Fix window gasketing') }

  it 'should render task' do
    @task = task
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => task.id,
                                        'name' => 'Fix window gasketing',
                                        'company_id' => task.company_id,
                                        'category_id' => task.category_id,
                                        'user_id' => task.user_id,
                                        'job_id' => task.job_id,
                                        'provider_id' => task.provider_id,
                                        'work_order_id' => task.work_order_id,
                                        'canceled_at' => nil,
                                        'completed_at' => nil,
                                        'declined_at' => nil,
                                        'description' => nil,
                                        'due_at' => nil,
                                        'status' => 'incomplete',
                                        'task_id' => nil,
                                    )
  end
end
