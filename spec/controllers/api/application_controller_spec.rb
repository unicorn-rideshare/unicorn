require 'rails_helper'

describe Api::ApplicationController, api: true do
  controller do
    def index
      render status: :ok, json: {}
    end
  end

  let(:user) { FactoryGirl.create(:user) }

  context 'when the user is not authenticated' do
    before { get :index }

    it { should respond_with(:unauthorized) }
  end

  context 'when the user is authenticated' do
    context 'authenticate_user!' do
      before do
        sign_in user
        get :index
      end

      it { should respond_with(:ok) }
    end

    context 'authenticate_token!' do
      before do
        token = FactoryGirl.create(:token, authenticable: user)
        user_pass = Base64.urlsafe_encode64("#{token.token}:#{token.uuid}")
        request.headers['X-API-Authorization'] = "Basic #{user_pass}"
        get :index
      end

      it { should respond_with(:ok) }
    end
  end
end
