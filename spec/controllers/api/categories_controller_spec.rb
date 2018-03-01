require 'rails_helper'

describe Api::CategoriesController, api: true do
  let(:user)       { FactoryGirl.create(:user) }
  let(:company)    { FactoryGirl.create(:company, user: user) }
  let(:category)   { FactoryGirl.create(:category, company: company) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show, :destroy do
    let(:resource) { category }
  end

  describe 'POST create' do
    describe 'with valid params' do
      let(:params) { { company_id: company.id, name: 'Concrete' } }
      subject { post :create, params }

      it 'creates a new Category' do
        expect { subject }.to change(Category, :count).by(1)
      end

      it 'assigns a newly created category as @category' do
        subject
        expect(assigns(:category)).to be_a(Category)
        expect(assigns(:category)).to be_persisted
      end

      it 'assigns the newly created category company' do
        subject
        expect(assigns(:category).company).to eq(company)
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
      subject { post :create, { company_id: company.id, name: nil } }

      it 'assigns a newly created but unsaved category as @category' do
        subject
        expect(assigns(:category)).to be_a_new(Category)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
            errors: {
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
            id: category.id,
            name: 'HVAC'
        }
        put :update, params
      end

      it 'updates the requested category' do
        params = {
          'name' => 'HVAC'
        }
        expect_any_instance_of(Category).to receive(:update).with(params)
        subject
      end

      it 'assigns the requested category as @category' do
        subject
        expect(assigns(:category)).to eq(category)
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
      subject { put :update, id: category.id, name: nil }

      it 'assigns the category as @category' do
        subject
        expect(assigns(:category)).to eq(category)
      end

      it 'returns a 204 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
            errors: {
                'name' => ["can't be blank"]
            }
        }.to_json
        expect(response.body).to eq(expected)
      end
    end
  end
end
