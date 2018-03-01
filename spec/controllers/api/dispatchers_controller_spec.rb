require 'rails_helper'

describe Api::DispatchersController, api: true do
  let!(:company) { FactoryGirl.create(:company, user: user) }
  let(:dispatcher) { FactoryGirl.create(:dispatcher, company: company) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show, :destroy do
    let(:resource) { dispatcher }
  end

  describe 'POST create' do
    describe 'with valid params' do
      subject { post :create, company_id: company.id, contact: { name: 'ABC Corp', email: 'joe@abc.com', time_zone_id: 'Eastern Time (US & Canada)'} }

      it 'creates a new Dispatcher' do
        expect { subject }.to change(Dispatcher, :count).by(1)
      end

      it 'assigns a newly created dispatcher as @dispatcher' do
        subject
        expect(assigns(:dispatcher)).to be_a(Dispatcher)
        expect(assigns(:dispatcher)).to be_persisted
      end

      it 'returns a 201 status code' do
        subject
        expect(response).to have_http_status(201)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end

      context 'when no user is already associated with the dispatcher contact email address' do
        let(:mobile) { nil }

        subject { post :create,
                       company_id: company.id,
                       contact: FactoryGirl.attributes_for(:contact, email: 'other@example.com', mobile: mobile) }

        it 'creates a new user and associates it with the newly created dispatcher using the dispatcher email contact address' do
          subject
          expect(assigns(:dispatcher).user).to be_a(User)
          expect(assigns(:dispatcher).user.email).to eq('other@example.com')
        end

        it 'invites the newly created user associated with the contact email address of the newly created dispatcher' do
          subject
          expect(assigns(:dispatcher).user.reload.invitations.count).to eq(1)
        end

        context 'when the dispatcher contact has a :mobile number' do
          let(:mobile) { '4041234567' }

          it 'invites the newly created user associated with the contact email address of the newly created dispatcher via email and SMS' do
            subject
            expect(assigns(:dispatcher).user.reload.invitations.count).to eq(2)
          end
        end
      end

      context 'when a user is already associated with the dispatcher contact email address' do
        let(:user) { FactoryGirl.create(:user, email: 'u@example.com') }

        subject { post :create, company_id: company.id, user_id: user.id }

        it 'associates the user with the newly created dispatcher' do
          subject
          expect(assigns(:dispatcher).user).to be_a(User)
          expect(assigns(:dispatcher).user).to eq(user)
        end

        it 'does not invite the user associated with the newly created dispatcher' do
          subject
          expect(assigns(:dispatcher).user.reload.invitations.count).to eq(0)
        end
      end
    end

    describe 'with invalid params' do
      subject { post :create, company_id: company.id, contact: {} }

      it 'assigns a newly created but unsaved dispatcher as @dispatcher' do
        subject
        expect(assigns(:dispatcher)).to be_a_new(Dispatcher)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
          errors: {
              'contact.name' => ["can't be blank"],
          }
        }.to_json
        expect(response.body).to eq(expected)
      end

      describe 'company_id is not specified' do
        subject { post :create }

        it 'should restrict access' do
          expect(subject).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      subject do
        params = {
          id: dispatcher.id,
          contact: {
            name: 'Foo',
            address1: 'Bar',
            time_zone_id: 'Eastern Time (US & Canada)'
          }
        }
        put :update, params
      end

      it 'updates the requested dispatcher' do
        params = {
          'contact_attributes' => {
            'name' => 'Foo',
            'address1' => 'Bar',
            'time_zone_id' => 'Eastern Time (US & Canada)'
          }
        }
        expect_any_instance_of(Dispatcher).to receive(:update).with(params)
        subject
      end

      it 'assigns the requested dispatcher as @dispatcher' do
        subject
        expect(assigns(:dispatcher)).to eq(dispatcher)
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

    describe 'with invalid params' do
      subject { put :update, id: dispatcher.id, contact: { name: nil, time_zone_id: 'Eastern Time (US & Canada)' } }

      it 'assigns the dispatcher as @dispatcher' do
        subject
        expect(assigns(:dispatcher)).to eq(dispatcher)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
          errors: {
            'contact.name' => ["can't be blank"]
          }
        }.to_json
        expect(response.body).to eq(expected)
      end
    end
  end
end
