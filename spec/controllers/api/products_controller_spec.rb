require 'rails_helper'

describe Api::ProductsController, api: true do
  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context 'when the requesting user is an admin of the specified company' do
    let(:company) { FactoryGirl.create(:company, user: user) }
    let(:product) { company.products.create }

    it_behaves_like 'api_controller', :index, :show, :update, :destroy do
      let(:resource)  { product }
    end

    describe '#create' do
      context 'with valid params' do
        let(:params) { { company_id: company.id, data: { name: 'TPS Report Generator' } } }

        subject { post :create, params }

        it 'creates a new Product' do
          expect { subject }.to change(Product, :count).by(1)
        end

        it 'assigns a newly created product as @product' do
          subject
          expect(assigns(:product)).to be_a(Product)
          expect(assigns(:product)).to be_persisted
        end

        it 'sets the product name' do
          subject
          expect(Product.first.data['name']).to eq('TPS Report Generator')
        end

        it 'returns a 201 status code' do
          subject
          expect(response).to have_http_status(201)
        end

        it 'should render the show template' do
          subject
          expect(response).to render_template('show')
        end

        context 'when a :gtin is provided' do
          let(:params) { { company_id: company.id, gtin: '1111111111111' } }

          subject { post :create, params }

          it 'populates the barcode image' do
            subject
            expect(Product.first.barcode_uri).to_not be_nil
          end
        end
      end
    end
  end
end
