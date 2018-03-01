require 'rails_helper'

describe 'api/tokens/show' do
  let(:token) { FactoryGirl.create :token }

  it 'should render token' do
    @token = token
    render
    expect(JSON.parse(rendered)).to eq(
      'id' => token.id,
      'token' => token.token,
      'uuid' => token.uuid,
      'user' => Rabl::Renderer.new('users/show',
                                   token.authenticable,
                                   view_path: 'app/views',
                                   format: 'hash').render.with_indifferent_access
    )
  end
end
