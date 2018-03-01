require 'rails_helper'

describe 'api/comments/index' do
  it 'should render a list of comments' do
    @comments = FactoryGirl.create_list(:comment, 3)
    json = JSON.parse(render template: 'api/comments/index', formats: ['json'])
    expect(json.count).to eq(3)
  end
end
