require 'rails_helper'

describe 'api/users/create' do
  let(:user)  { FactoryGirl.create(:user, name: 'Joe User', email: 'joe@gmail.com') }
  let(:token) { FactoryGirl.create(:token, authenticable: user) }

  context 'when a user is in scope' do
    it 'should render the user' do
      @user = user
      render
      expect(JSON.parse(rendered)['user']).to_not eq(nil)
    end
  end

  context 'when a token is in scope' do
    it 'should render the token' do
      @user = user
      @token = Token.create(authenticable: @user)
      render
      expect(JSON.parse(rendered)['token']).to_not eq(nil)
    end
  end
end
