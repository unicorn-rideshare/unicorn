require 'rails_helper'

describe Api::MarketsController, api: true do
  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context 'when the requesting user is an admin of the specified company' do
    let(:company) { FactoryGirl.create(:company, user: user) }
    let(:market)  { FactoryGirl.create(:market, company: company) }

    it_behaves_like 'api_controller', :index, :show, :update, :destroy do
      let(:resource) { market }
    end

    describe '#create' do
      context 'with valid params' do
        let(:params) { { company_id: company.id, name: Faker::Address.city } }

        subject { post :create, params }

        it 'creates a new Market' do
          expect { subject }.to change(Market, :count).by(1)
        end

        it 'assigns a newly created market as @market' do
          subject
          expect(assigns(:market)).to be_a(Market)
          expect(assigns(:market)).to be_persisted
        end

        it 'assigns the newly created market company' do
          subject
          expect(assigns(:market).company).to eq(company)
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
        context 'with invalid company id' do
          subject { post :create, company_id: nil }

          it 'should restrict access' do
            expect(subject).to have_http_status(:unprocessable_entity)
          end
        end

        context 'with no name for the market' do
          subject { post :create, company_id: company.id, name: nil }

          it 'should return a 422 status' do
            expect(subject).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end
end
