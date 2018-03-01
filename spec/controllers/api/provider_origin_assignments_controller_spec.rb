require 'rails_helper'

describe Api::ProviderOriginAssignmentsController, api: true do
  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context 'when the requesting user is an admin of the specified company' do
    let(:company)                     { FactoryGirl.create(:company, user: user) }
    let(:market)                      { FactoryGirl.create(:market, company: company) }
    let(:origin)                      { market.origins.create }
    let(:provider)                    { FactoryGirl.create(:provider, company: company) }
    let(:provider_origin_assignment)  { FactoryGirl.create(:provider_origin_assignment,
                                                           provider: provider,
                                                           origin: origin,
                                                           start_date: Date.today,
                                                           end_date: Date.today) }

    it_behaves_like 'api_controller', :index, :show, :update, :destroy do
      let(:resource)        { provider_origin_assignment }
      let(:resource_params) { { market_id: market.id, origin_id: origin.id, id: provider_origin_assignment.id } }
    end

    describe '#index' do
      context 'when an effective_on parameter is provided' do
        before do
          provider_origin_assignment.start_date = '2015-02-05'
          provider_origin_assignment.save
        end

        subject { get :index, params }

        context 'when the specified effective_on parameter is prior to the assignment effective date' do
          let(:params) { { market_id: market.id, origin_id: origin.id, effective_on: '2015-02-04' } }

          it 'does not include the provider origin assignment in the @provider_origin_assignments response' do
            subject
            expect(assigns(:provider_origin_assignments)).to eq([])
          end

          it 'returns a 200 status code' do
            subject
            expect(response).to have_http_status(200)
          end

          it 'should render the index template' do
            subject
            expect(response).to render_template('index')
          end
        end

        context 'when the specified effective_on parameter is equal to the assignment effective date' do
          let(:params) { { market_id: market.id, origin_id: origin.id, effective_on: '2015-02-05' } }

          it 'includes the provider origin assignment in the @provider_origin_assignments response' do
            subject
            expect(assigns(:provider_origin_assignments)).to eq([provider_origin_assignment])
          end

          it 'returns a 200 status code' do
            subject
            expect(response).to have_http_status(200)
          end

          it 'should render the index template' do
            subject
            expect(response).to render_template('index')
          end
        end

        context 'when the specified effective_on parameter is after the assignment effective date' do
          let(:params) { { market_id: market.id, origin_id: origin.id, effective_on: '2015-02-06' } }

          it 'includes the provider origin assignment in the @provider_origin_assignments response' do
            subject
            expect(assigns(:provider_origin_assignments)).to eq([provider_origin_assignment])
          end

          it 'returns a 200 status code' do
            subject
            expect(response).to have_http_status(200)
          end

          it 'should render the index template' do
            subject
            expect(response).to render_template('index')
          end
        end
      end
    end

    describe '#create' do
      context 'when the provider has an existing origin assignment' do
        let(:start_date) { Date.today }
        let(:end_date)   { start_date }

        context 'when the existing origin assignment has a start and end date' do
          before do
            FactoryGirl.create(:provider_origin_assignment,
                               provider: provider,
                               origin: origin,
                               start_date: start_date - 1.day,
                               end_date: end_date - 1.day)
          end

          context 'with valid params' do
            let(:params) { { market_id: market.id, origin_id: origin.id, provider_id: provider.id, start_date: start_date.to_s, end_date: end_date.to_s } }

            subject { post :create, params }

            it 'creates a new ProviderOriginAssignment' do
              expect { subject }.to change(ProviderOriginAssignment, :count).by(1)
            end

            it 'assigns a newly created provider_origin_assignment as @provider_origin_assignment' do
              subject
              expect(assigns(:provider_origin_assignment)).to be_a(ProviderOriginAssignment)
              expect(assigns(:provider_origin_assignment)).to be_persisted
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

      context 'when there is not an existing origin assignment' do
        context 'with valid params' do
          let(:params) { { market_id: market.id, origin_id: origin.id, provider_id: provider.id, start_date: Date.today.to_s, end_date: Date.today.to_s } }

          subject { post :create, params }

          it 'creates a new ProviderOriginAssignment' do
            expect { subject }.to change(ProviderOriginAssignment, :count).by(1)
          end

          it 'assigns a newly created provider_origin_assignment as @provider_origin_assignment' do
            subject
            expect(assigns(:provider_origin_assignment)).to be_a(ProviderOriginAssignment)
            expect(assigns(:provider_origin_assignment)).to be_persisted
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
        
        context 'with no date range params' do
          let(:params) { { market_id: market.id, origin_id: origin.id, provider_id: provider.id } }

          subject { post :create, params }

          it 'does not create a new ProviderOriginAssignment' do
            expect { subject }.to change(ProviderOriginAssignment, :count).by(0)
          end

          it 'returns a 422 status code' do
            subject
            expect(response).to have_http_status(422)
          end
        end
      end
    end
  end
end
