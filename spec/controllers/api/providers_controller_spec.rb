require 'rails_helper'

describe Api::ProvidersController, api: true do
  let(:company) { FactoryGirl.create(:company, user: user) }
  let(:provider) { FactoryGirl.create(:provider, company: company) }
  let(:category) { FactoryGirl.create(:category, company: company) }
  let(:user)     { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show, :destroy do
    let(:resource) { provider }
  end

  describe 'POST create' do
    context 'when a user makes the request' do
      describe 'company_id is not specified' do
        subject { post :create }

        it 'should create a publicly available provider' do
          subject
          expect(assigns(:provider).publicly_available).to eq(true)
        end
      end

      subject { post :create }

      context 'when a company admin makes the request' do
        describe 'with valid params' do
          subject { post :create,
                         company_id: company.id,
                         user_id: other_user.id,
                         contact: FactoryGirl.attributes_for(:contact, email: other_user.email),
                         category_ids: [category.id] }

          it 'creates a new Provider' do
            expect { subject }.to change(Provider, :count).by(1)
          end

          it 'assigns a newly created provider as @provider' do
            subject
            expect(assigns(:provider)).to be_a(Provider)
            expect(assigns(:provider)).to be_persisted
          end

          it 'returns a 201 status code' do
            subject
            expect(response).to have_http_status(201)
          end

          it 'should render the show template' do
            subject
            expect(response).to render_template('show')
          end

          it 'assigns the :provider role to the user associated with the new provider' do
            subject
            expect(assigns(:provider).user.has_role?(:provider, company)).to eq(true)
          end

          it 'associates the :provider with the given category' do
            subject
            expect(assigns(:provider).categories).to eq([category])
          end

          context 'when no user is already associated with the provider contact email address' do
            let(:mobile) { nil }

            subject { post :create,
                           company_id: company.id,
                           contact: FactoryGirl.attributes_for(:contact).merge(email: 'other@example.com', mobile: mobile) }

            it 'creates a new user and associates it with the newly created provider using the provider email contact address' do
              subject
              expect(assigns(:provider).user).to be_a(User)
              expect(assigns(:provider).user.email).to eq('other@example.com')
            end

            it 'invites the newly created user associated with the contact email address of the newly created provider' do
              subject
              expect(assigns(:provider).user.reload.invitations.count).to eq(1)
            end

            context 'when the provider contact has a :mobile number' do
              let(:mobile) { '4041234567' }

              it 'invites the newly created user associated with the contact email address of the newly created provider via email and SMS' do
                subject
                expect(assigns(:provider).user.reload.invitations.count).to eq(2)
              end
            end
          end

          context 'when a user is already associated with the provider contact email address' do
            let(:user) { FactoryGirl.create(:user, email: 'u@example.com') }

            subject { post :create, company_id: company.id, user_id: user.id }

            it 'associates the user with the newly created provider' do
              subject
              expect(assigns(:provider).user).to be_a(User)
              expect(assigns(:provider).user).to eq(user)
            end

            it 'does not invite the user associated with the newly created provider' do
              subject
              expect(assigns(:provider).user.reload.invitations.count).to eq(0)
            end
          end

          context 'when no :time_zone_id is provided with the contact' do
            let(:contact_attributes) { FactoryGirl.attributes_for(:contact, email: other_user.email) }

            before { contact_attributes.delete(:time_zone_id) }

            subject { post :create,
                           company_id: company.id,
                           user_id: other_user.id,
                           contact: contact_attributes,
                           category_ids: [category.id] }

            it 'returns a 201 status code' do
              subject
              expect(response).to have_http_status(201)
            end

            it 'should render the show template' do
              subject
              expect(response).to render_template('show')
            end

            it 'assigns the :provider contact a default :time_zone_id equal to that of the company' do
              subject
              expect(assigns(:provider).contact.time_zone_id).to eq(company.contact.time_zone_id)
            end
          end
        end

        describe 'with invalid params' do
          subject { post :create, company_id: company.id, contact: { time_zone_id: 'Eastern Time (US & Canada)' } }

          it 'assigns a newly created but unsaved provider as @provider' do
            subject
            expect(assigns(:provider)).to be_a_new(Provider)
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

          describe 'company_id is not specified' do
            before { sign_in(company.admins.first) }

            subject { post :create }

            it 'should restrict access' do
              expect(subject).to have_http_status(:forbidden)
            end
          end
        end
      end

      context 'when a company dispatcher makes the request' do
        let(:dispatcher) { FactoryGirl.create(:dispatcher, :with_user, company: company) }
        before { sign_in dispatcher.user }

        describe 'with valid params' do
          subject { post :create, company_id: company.id, user_id: other_user.id, name: 'ABC Corp' }

          it 'creates a new Provider' do
            expect { subject }.to change(Provider, :count).by(1)
          end

          it 'assigns a newly created provider as @provider' do
            subject
            expect(assigns(:provider)).to be_a(Provider)
            expect(assigns(:provider)).to be_persisted
          end

          it 'returns a 201 status code' do
            subject
            expect(response).to have_http_status(201)
          end

          it 'should render the show template' do
            subject
            expect(response).to render_template('show')
          end

          it 'assigns the :provider role to the new user' do
            subject
            expect(assigns(:provider).user.has_role?(:provider, company)).to eq(true)
          end

          context 'when no user is already associated with the provider contact email address' do
            let(:mobile) { nil }

            subject { post :create,
                           company_id: company.id,
                           contact: FactoryGirl.attributes_for(:contact, email: 'other@example.com', mobile: mobile) }

            it 'creates a new user and associates it with the newly created provider using the provider email contact address' do
              subject
              expect(assigns(:provider).user).to be_a(User)
              expect(assigns(:provider).user.email).to eq('other@example.com')
            end

            it 'invites the newly created user associated with the contact email address of the newly created provider' do
              subject
              expect(assigns(:provider).user.reload.invitations.count).to eq(1)
            end

            context 'when the provider contact has a :mobile number' do
              let(:mobile) { '4041234567' }

              it 'invites the newly created user associated with the contact email address of the newly created provider via email and SMS' do
                subject
                expect(assigns(:provider).user.reload.invitations.count).to eq(2)
              end
            end
          end

          context 'when a user is already associated with the provider contact email address' do
            let(:user) { FactoryGirl.create(:user, email: 'u@example.com') }

            subject { post :create, company_id: company.id, user_id: user.id }

            it 'associates the user with the newly created provider' do
              subject
              expect(assigns(:provider).user).to be_a(User)
              expect(assigns(:provider).user).to eq(user)
            end

            it 'does not invite the user associated with the newly created provider' do
              subject
              expect(assigns(:provider).user.reload.invitations.count).to eq(0)
            end
          end
        end

        describe 'with invalid params' do
          subject { post :create, company_id: company.id, contact: { time_zone_id: nil } }

          it 'assigns a newly created but unsaved provider as @provider' do
            subject
            expect(assigns(:provider)).to be_a_new(Provider)
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
    end

    context 'when a company makes the request via the api' do
      before { sign_in company }

      describe 'with valid params' do
        subject { post :create, company_id: company.id, contact: { name: 'ABC Corp', email: 'joe@abc.com', time_zone_id: 'Eastern Time (US & Canada)'} }

        it 'creates a new Provider' do
          expect { subject }.to change(Provider, :count).by(1)
        end

        it 'assigns a newly created provider as @provider' do
          subject
          expect(assigns(:provider)).to be_a(Provider)
          expect(assigns(:provider)).to be_persisted
        end

        it 'returns a 201 status code' do
          subject
          expect(response).to have_http_status(201)
        end

        it 'should render the show template' do
          subject
          expect(response).to render_template('show')
        end

        it 'creates and invites a user associated with the newly created provider' do
          subject
          expect(assigns(:provider).user).to be_a(User)
          expect(assigns(:provider).user.reload.invitations.count).to eq(1)
        end

        it 'assigns the :provider role to the new user' do
          subject
          expect(assigns(:provider).user.has_role?(:provider, company)).to eq(true)
        end
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      subject do
        params = {
          id: provider.id,
          contact: {
            name: 'Foo',
            address1: 'Bar',
            time_zone_id: 'Eastern Time (US & Canada)'
          }
        }
        put :update, params
      end

      it 'updates the requested provider' do
        params = {
          'contact_attributes' => {
            'name' => 'Foo',
            'address1' => 'Bar',
            'time_zone_id' => 'Eastern Time (US & Canada)'
          }
        }
        expect_any_instance_of(Provider).to receive(:update).with(params)
        subject
      end

      it 'assigns the requested provider as @provider' do
        subject
        expect(assigns(:provider)).to eq(provider)
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
      subject { put :update, id: provider.id, contact: { name: nil, time_zone_id: 'Eastern Time (US & Canada)' } }

      it 'assigns the provider as @provider' do
        subject
        expect(assigns(:provider)).to eq(provider)
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

  describe '#availability' do
    let(:customer) { FactoryGirl.create(:customer, company: company) }

    context 'with valid params' do
      let(:params) do
        {
            company_id: company.id,
            customer_id: customer.id,
            start_date: '2014-07-17',
            end_date: '2014-07-18',
            estimated_duration: 60,
            provider_ids: [provider.id]
        }
      end
      subject { get :availability, params }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'should render the available template' do
        subject
        availability = WorkOrderService.calculate_availability(params)
        expect(response.body).to eq(availability.to_json)
      end
    end
  end
end
