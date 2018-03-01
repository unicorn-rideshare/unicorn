require 'rails_helper'

describe 'api/tasks/index' do
  it 'should render a list of tasks' do
    @tasks = FactoryGirl.create_list(:task, 3)
    json = JSON.parse(render template: 'api/tasks/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
