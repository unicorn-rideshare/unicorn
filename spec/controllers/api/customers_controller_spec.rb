require 'rails_helper'

describe Api::CustomersController, api: true do
  let(:company) { FactoryGirl.create(:company, user: user) }
  let(:customer) { FactoryGirl.create(:customer, company: company) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show, :destroy do
    let(:resource) { customer }
  end

  describe 'POST create' do
    describe 'with valid params' do
      let(:contact_params) { { name: 'Provide', address1: '123 Test St', time_zone_id: 'Eastern Time (US & Canada)' } }
      subject { post :create, company_id: company.id, user_id: other_user.id, contact: contact_params }

      it 'creates a new Customer' do
        expect { subject }.to change(Customer, :count).by(1)
      end

      it 'assigns a newly created customer as @customer' do
        subject
        expect(assigns(:customer)).to be_a(Customer)
        expect(assigns(:customer)).to be_persisted
      end

      it 'returns a 201 status code' do
        subject
        expect(response).to have_http_status(201)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end
    end

    describe 'with invalid params' do
      subject { post :create, company_id: company.id, contact: {} }

      it 'assigns a newly created but unsaved customer as @customer' do
        subject
        expect(assigns(:customer)).to be_a_new(Customer)
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
          id: customer.id,
          contact: {
            name: 'Foo',
            address1: 'Bar',
            time_zone_id: 'Eastern Time (US & Canada)'
          }
        }
        put :update, params
      end

      it 'updates the requested customer' do
        params = {
            'name' => 'Foo',
            'contact_attributes' => {
                'name' => 'Foo',
                'address1' => 'Bar',
                'time_zone_id' => 'Eastern Time (US & Canada)'
            }
        }
        expect_any_instance_of(Customer).to receive(:update).with(params)
        subject
      end

      it 'assigns the requested customer as @customer' do
        subject
        expect(assigns(:customer)).to eq(customer)
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
      subject { put :update, id: customer.id, contact: { name: nil, time_zone_id: 'Eastern Time (US & Canada)' } }

      it 'assigns the customer as @customer' do
        subject
        expect(assigns(:customer)).to eq(customer)
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
