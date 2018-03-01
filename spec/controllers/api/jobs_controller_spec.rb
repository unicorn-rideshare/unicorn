require 'rails_helper'

describe Api::JobsController, api: true do
  let(:user)     { FactoryGirl.create(:user) }
  let(:company)  { FactoryGirl.create(:company, user: user) }
  let(:customer) { FactoryGirl.create(:customer, company: company) }
  let(:job)      { FactoryGirl.create(:job, company: company) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :destroy do
    let(:resource) { job }
  end

  context 'when the user is a company administrator' do
    describe 'POST create' do
      describe 'with valid params' do
        let(:params) { { company_id: company.id, customer_id: customer.id, type: 'commercial' }  }

        subject { post :create, params }

        it 'creates a new Job' do
          expect { subject }.to change(Job, :count).by(1)
        end

        it 'assigns a newly created job as @job' do
          subject
          expect(assigns(:job)).to be_a(Job)
          expect(assigns(:job)).to be_persisted
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

      describe 'with invalid company id' do
        subject { post :create, company_id: FactoryGirl.create(:company).id, type: 'commercial' }

        it 'assigns a newly created but unsaved job as @job' do
          subject
          expect(assigns(:job)).to be_a_new(Job)
        end

        it 'returns a 403 status code' do
          subject
          expect(response).to have_http_status(403)
        end
      end
    end

    describe 'PUT update' do
      describe 'with valid params' do
        subject { put :update, id: job.id, blueprint_scale: 4.5 }

        it 'creates a new Job' do
          expect { subject }.to change(Job, :count).by(1)
        end

        it 'assigns a newly created job as @job' do
          subject
          expect(assigns(:job)).to be_a(Job)
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end

        context 'when the request contains a :supervisors parameter' do
          context 'when the :supervisors parameter contains one or more providers' do
            let(:supervisor)  { FactoryGirl.create(:provider, company: job.company) }

            subject { put :update, id: job.id, supervisors: [ { id: supervisor.id } ] }

            it 'creates a new supervisor relationship using the given provider id' do
              subject
              expected_job_supervisors = [supervisor]
              expect(expected_job_supervisors.count).to eq(1)
              expect(assigns(:job)).to be_persisted
              expect(assigns(:job).reload.supervisors.to_a).to eq(expected_job_supervisors)
            end
          end

          context 'when the :supervisors parameter is an empty array' do
            let(:job) { FactoryGirl.create(:job, company: company) }

            subject { put :update, id: job.id, supervisors: [] }

            it 'removes all existing job supervisors' do
              subject
              expect(assigns(:job)).to be_persisted
              expect(assigns(:job).reload.supervisors.to_a).to eq([])
            end
          end
        end

        context 'when the request contains a :materials parameter' do
          context 'when the :materials parameter contains one or more job products' do
            let(:product1)  { FactoryGirl.create(:product, company: job.company) }
            let(:materials) { [ { product_id: product1.id }.with_indifferent_access ] }

            subject { put :update, id: job.id, materials: materials }

            it 'creates a new job product relationship using the given product_id' do
              subject
              expected_job_products = JobProduct.where(job_id: job.id, product_id: product1.id).to_a
              expect(expected_job_products.count).to eq(1)
              expect(assigns(:job)).to be_persisted
              expect(assigns(:job).materials.to_a).to eq(expected_job_products)
            end
          end

          context 'when the :materials parameter is an empty array' do
            let(:job) { FactoryGirl.create(:job, :with_materials, company: company) }

            before { expect(job.materials.to_a.size).to eq(3) }

            subject { put :update, id: job.id, materials: [] }

            it 'removes all existing job product relationships' do
              subject
              expect(assigns(:job)).to be_persisted
              expect(assigns(:job).reload.materials.to_a).to eq([])
            end
          end
        end
      end
    end
  end

  context 'when the user is a company provider' do
    let(:provider) { FactoryGirl.create(:provider, :with_user, company: company) }
    before { sign_in provider.user }

    describe 'POST create' do
      describe 'with valid params' do
        subject { post :create, company_id: company.id, customer_id: customer.id, type: 'commercial' }

        it 'does not create a new Job' do
          expect { subject }.to change(Job, :count).by(0)
        end

        it 'assigns a job as @job' do
          subject
          expect(assigns(:job)).to be_a(Job)
          expect(assigns(:job)).not_to be_persisted
        end

        it 'returns a 403 status code' do
          subject
          expect(response).to have_http_status(403)
        end
      end
    end

    describe 'PUT update' do
      context 'when the provider is not a work order provider on any of the job work orders' do
        describe 'with valid params' do
          subject { put :update, id: job.id, blueprint_scale: 4.5 }

          it 'assigns a newly created job as @job' do
            subject
            expect(assigns(:job)).to be_a(Job)
          end

          it 'returns a 403 status code' do
            subject
            expect(response).to have_http_status(403)
          end
        end
      end

      context 'when the provider is a work order provider on any of the job work orders' do
        before { job.work_orders << FactoryGirl.create(:work_order,
                                                       :with_provider,
                                                       company: job.company,
                                                       customer: FactoryGirl.create(:customer, company: job.company),
                                                       provider: provider) }

        describe 'with valid params' do
          subject { put :update, id: job.id, blueprint_scale: 4.5 }

          it 'assigns a newly created job as @job' do
            subject
            expect(assigns(:job)).to be_a(Job)
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(204)
          end
        end
      end
    end
  end
end
