require 'rails_helper'

describe 'api/jobs/index' do
  it 'should render a list of jobs' do
    @jobs = FactoryGirl.create_list(:job, 3)
    json = JSON.parse(render template: 'api/jobs/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
