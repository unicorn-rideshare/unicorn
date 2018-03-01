require 'rails_helper'

describe Api::TokensController, api: true do
  let(:token) { FactoryGirl.create(:token, authenticable: user) }
  let(:user)  { FactoryGirl.create(:user) }

  it_behaves_like 'api_controller', :destroy do
    let(:resource) { token }
  end

  describe '#create' do
    context 'when a user provides a valid email address and password' do
      context 'when no role is requested' do
        before { post :create, email: user.email, password: user.password }

        it { expect(assigns(:token)).to eq(Token.first) }
        it { should respond_with(:created) }
        it { should render_template('show') }
      end
    end

    context 'when a user provides an invalid email address and password' do
      context 'when no role is requested' do
        before { post :create, email: 'joe_user@example.com', password: 'just wrong...' }

        it { expect(assigns(:token)).to be_nil }
        it { should respond_with(:unauthorized) }
      end
    end
  end
end
