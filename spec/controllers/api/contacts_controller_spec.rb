require 'rails_helper'

describe Api::ContactsController, api: true do
  let(:company) { FactoryGirl.create(:company, user: user) }
  let(:contact) { company.contact }
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :show do
    let(:resource) { contact }
  end

  describe 'PUT update' do
    describe 'with valid params' do
      subject { put :update, id: contact.id, address1: 'MyString' }

      it 'updates the requested contact' do
        expect_any_instance_of(Contact).to receive(:update).with('address1' => 'MyString')
        subject
      end

      it 'assigns the requested contact as @contact' do
        subject
        expect(assigns(:contact)).to eq(contact)
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
end
