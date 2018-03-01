require 'rails_helper'

describe Api::OriginsController, api: true do
  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context 'when the requesting user is an admin of the specified company' do
    let(:company) { FactoryGirl.create(:company, user: user) }
    let(:market)  { FactoryGirl.create(:market, company: company) }
    let(:origin)  { market.origins.create }

    it_behaves_like 'api_controller', :index, :show, :update, :destroy do
      let(:resource)        { origin }
      let(:resource_params) { { market_id: market.id, id: origin.id } }
    end

    describe '#create' do
      context 'with valid params' do
        let(:params) { { market_id: market.id } }

        subject { post :create, params }

        it 'creates a new Origin' do
          expect { subject }.to change(Origin, :count).by(1)
        end

        it 'assigns a newly created origin as @origin' do
          subject
          expect(assigns(:origin)).to be_a(Origin)
          expect(assigns(:origin)).to be_persisted
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
    end
  end
end
