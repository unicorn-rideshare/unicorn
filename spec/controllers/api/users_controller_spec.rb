require 'rails_helper'

describe Api::UsersController, api: true do
  let(:user)       { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  it_behaves_like 'api_controller', :show do
    let(:resource) { user }
  end

  describe '#create' do
    let(:valid_params) { { name: 'Test User', email: 'test@example.com', password: 'test123' } }

    describe 'with valid params' do
      before { post :create, valid_params }

      it { expect(assigns(:user)).to eq(User.first) }
      it { expect(assigns(:user)).to_not eq(nil) }

      it { expect(assigns(:token)).to eq(Token.first) }
      it { expect(assigns(:token)).to_not eq(nil) }

      it { should respond_with(:created) }
      it { should render_template('create') }
    end

    context 'when the email address has already been registered' do
      before do
        FactoryGirl.create(:user, email: valid_params[:email])
        post :create, valid_params
      end

      it { should respond_with(:conflict) }
    end

    context 'when the params contain an :invitation_token' do
      let(:user)          { FactoryGirl.create(:user, email: valid_params[:email]) }
      let(:invited_user)  { FactoryGirl.create(:user) }
      let(:invitation)    { invited_user.invitations.create(sender: user) }

      context 'when the invitation is valid' do
        context 'when the given email address matches the invited user' do
          before { post :create, { name: invited_user.name,
                                   email: invited_user.email,
                                   password: invited_user.password,
                                   invitation_token: invitation.token } }

          it { expect(assigns(:user)).to eq(invited_user) }
          it { expect(assigns(:user)).to_not eq(nil) }

          it { expect(assigns(:token)).to eq(invited_user.tokens.first) }
          it { expect(assigns(:token)).to_not eq(nil) }

          it { should respond_with(:created) }
          it { should render_template('create') }
        end

        context 'when the given email address does not match the invited user' do
          before { post :create, valid_params.merge(email: 'scriptkiddie@example.com', invitation_token: invitation.token) }

          it { should respond_with(:unprocessable_entity) }
        end
      end

      context 'when the invitation has expired' do
        #it { should respond_with(:unprocessable_entity) }
      end
    end
  end

  describe '#update' do
    before { sign_in user }

    describe 'with valid params' do
      subject { put :update, id: user.id, name: 'Joe B. User' }

      it 'updates the requested user' do
        expect_any_instance_of(User).to receive(:update).with('name' => 'Joe B. User')
        subject
      end

      it 'assigns the requested user as @user' do
        subject
        expect(assigns(:user)).to eq(user)
      end

      it 'returns a 204 status code' do
        subject
        expect(response).to have_http_status(204)
      end

      it 'response body is empty' do
        subject
        expect(response.body).to eq('')
      end

      context 'another user is signed in' do
        before { sign_in other_user }

        it 'should restrict access' do
          expect(subject).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe '#reset_password' do
    context 'when the params do not contain a reset password token' do
      context 'when the params contain a valid email address' do
        subject { post :reset_password, email: user.email }

        it 'updates the requested user' do
          expect_any_instance_of(User).to receive(:reset_password).once
          subject
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end
      end
    end

    context 'when the params contain a reset password token' do
      context 'when the params contain a valid reset password token' do
        before  { user.reset_password }
        subject { post :reset_password, email: user.email, reset_password_token: user.reset_password_token, password: 'some-new-password' }

        it 'updates the requested user' do
          expect_any_instance_of(User).to receive(:update).with(password: 'some-new-password', reset_password_token: nil, reset_password_sent_at: nil)
          subject
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end
      end

      context 'when the params contain a reset password token that does not match' do
        subject { post :reset_password, email: user.email, reset_password_token: 'some-invalid-token', password: 'some-new-password' }

        it 'returns a 422 status code' do
          subject
          expect(response).to have_http_status(422)
        end
      end

      context 'when the params contain an email address that does not exist' do
        before  { user.reset_password }
        subject { post :reset_password, email: 'user@example.com', reset_password_token: user.reset_password_token, password: 'some-new-password' }

        it 'returns a 422 status code' do
          subject
          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
