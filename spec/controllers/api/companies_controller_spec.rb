require 'rails_helper'

describe Api::CompaniesController, api: true do
  let(:company) { FactoryGirl.create(:company, user: user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show, :update do
    let(:resource) { company }
  end

  describe 'POST create' do
    describe 'with valid params' do
      let(:contact_params) { { name: 'Provide', address1: '123 Test St', time_zone_id: 'Eastern Time (US & Canada)' } }
      subject { post :create, contact: contact_params }

      it 'creates a new Company' do
        expect { subject }.to change(Company, :count).by(1)
      end

      it 'assigns a newly created company as @company' do
        subject
        expect(assigns(:company)).to be_a(Company)
        expect(assigns(:company)).to be_persisted
      end

      it 'assigns the newly created company user' do
        subject
        expect(assigns(:company).user).to eq(user)
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
      subject { post :create, contact: {} }

      it 'assigns a newly created but unsaved company as @company' do
        subject
        expect(assigns(:company)).to be_a_new(Company)
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
              'name' => ["can't be blank"]
          }
        }.to_json
        expect(response.body).to eq(expected)
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      subject do
        params = {
          id: company.id,
          contact: {
            name: 'Foo',
            address1: 'Bar',
            time_zone_id: 'Eastern Time (US & Canada)'
          }
        }
        put :update, params
      end

      it 'updates the requested company' do
        params = {
            'name' => 'Foo',
            'contact_attributes' => {
                'name' => 'Foo',
                'address1' => 'Bar',
                'time_zone_id' => 'Eastern Time (US & Canada)'
            }
        }
        expect_any_instance_of(Company).to receive(:update).with(params)
        subject
      end

      it 'assigns the requested company as @company' do
        subject
        expect(assigns(:company)).to eq(company)
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
      subject { put :update, id: company.id, contact: { name: nil, time_zone_id: 'Eastern Time (US & Canada)' } }

      it 'assigns the company as @company' do
        subject
        expect(assigns(:company)).to eq(company)
      end

      it 'returns a 204 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
          errors: {
              'contact.name' => ["can't be blank"],
              'name' => ["can't be blank"]
          }
        }.to_json
        expect(response.body).to eq(expected)
      end
    end
  end
end
