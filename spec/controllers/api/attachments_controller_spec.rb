require 'rails_helper'

describe Api::AttachmentsController, api: true do
  let(:company)    { FactoryGirl.create(:company) }
  let(:work_order) { FactoryGirl.create(:work_order, company: company) }
  let(:job)        { FactoryGirl.create(:job, company: company) }
  let(:expense)    { FactoryGirl.create(:expense, expensable: job) }

  shared_examples 'crud' do
    before { sign_in user }

    describe '#index' do
      subject { attachment_params.delete(:id); get :index, attachment_params }

      it 'returns an OK (200) status code' do
        subject
        expect(response.status).to eq(200)
      end

      it 'exposes the attachments on the attachable' do
        subject
        expect(JSON.parse(response.body).size).to eq(expected_index_attachments_count)
      end
    end

    describe '#destroy' do
      before { delete :destroy, attachment_params }

      it 'should return the appropriate http status code' do
        expect(response).to have_http_status(expected_destroy_status)
      end
    end

    describe '#create' do
      describe 'with valid params' do
        subject { post :create, valid_create_attachment_params }

        it 'creates a new attachment' do
          expect { subject }.to change(Attachment, :count).by(1)
        end

        it 'assigns a newly created attachment as @attachment' do
          subject
          expect(assigns(:attachment)).to be_a(Attachment)
          expect(assigns(:attachment)).to be_persisted
          expect(assigns(:attachment).attachable_type).to eq(expected_attachable_type)
          expect(assigns(:attachment).attachable_id).to eq(expected_attachable_id)
        end

        it 'assigns the newly created attachment user' do
          subject
          expect(assigns(:attachment).user).to eq(user)
        end

        it 'returns a 201 status code' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'should render the show template' do
          subject
          expect(response).to render_template('show')
        end

        context 'when the tags are provided as an array' do
          subject { post :create, valid_create_attachment_params.merge(tags: %w(tag1 tag2)) }

          it 'parses the :tags parameter as an array' do
            subject
            expect(assigns(:attachment).reload.try(:tags)).to eq(%w(tag1 tag2))
          end
        end

        context 'when the tags are provided as a comma-delimited string' do
          subject { post :create, valid_create_attachment_params.merge(tags: 'tag1, tag2') }

          it 'parses the :tags parameter as an array' do
            subject
            expect(assigns(:attachment).try(:tags)).to eq(%w(tag1 tag2))
          end
        end
      end

      context 'when the attachable already has a default profile image' do
        let(:attachable) { attachment.attachable }
        let(:old_profile_image) { attachable.attachments.create(user: user,
                                                                tags: %w(default profile_image),
                                                                url: 'http://cdn.example.com/old_photo.jpg') }

        before { old_profile_image }

        context 'when a new attachment is created with both :default and :profile_image tags' do
          subject { post :create, valid_create_attachment_params.merge(description: 'This is a attachment.',
                                                                       tags: %w(profile_image default),
                                                                       url: 'http://cdn.example.com/hello.jpg') }

          it 'creates a new attachment which is immediately recognized as the new profile image for the user' do
            subject
            expect(attachable.reload.profile_image_url).to eq('http://cdn.example.com/hello.jpg')
          end

          it 'removes the default tag from the old profile image' do
            subject
            expect(old_profile_image.reload.tags).to eq(['profile_image'])
          end
        end
      end
    end

    describe '#update' do
      describe 'with valid params' do
        subject { put :update, valid_create_attachment_params.merge(id: attachment.id, metadata: { hello: 'world'}) }

        it 'assigns the updated attachment as @attachment' do
          subject
          expect(assigns(:attachment)).to be_a(Attachment)
          expect(assigns(:attachment)).to be_persisted
          expect(assigns(:attachment).attachable_type).to eq(expected_attachable_type)
          expect(assigns(:attachment).attachable_id).to eq(expected_attachable_id)
          expect(assigns(:attachment).reload.metadata).to eq({ 'hello' => 'world' })
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end
      end
    end
  end

  context 'when the authenticated user is a company administrator' do
    context 'when the attachable instance is a user' do
      it_should_behave_like 'crud' do
        let(:user) { work_order.company.user }
        let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: user) }
        let(:attachment_params)  { { id: attachment.id, user_id: user.id } }
        let(:expected_index_attachments_count) { 1 }
        let(:expected_attachable_type) { User.name }
        let(:expected_attachable_id) { user.id }
        let(:valid_create_attachment_params) { { user_id: user.id, description: 'This is an attachment.' } }
        let(:expected_destroy_status) { :no_content }
      end
    end

    context 'when the attachable instance is a work order' do
      it_should_behave_like 'crud' do
        let(:user) { work_order.company.user }
        let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: work_order) }
        let(:attachment_params)  { { id: attachment.id, work_order_id: work_order.id } }
        let(:expected_index_attachments_count) { 1 }
        let(:expected_attachable_type) { WorkOrder.name }
        let(:expected_attachable_id) { work_order.id }
        let(:valid_create_attachment_params) { { work_order_id: work_order.id, description: 'This is an attachment.' } }
        let(:expected_destroy_status) { :no_content }
      end
    end

    context 'when the attachable instance is a job' do
      it_should_behave_like 'crud' do
        let(:user) { work_order.company.user }
        let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: job) }
        let(:attachment_params)  { { id: attachment.id, job_id: job.id } }
        let(:expected_index_attachments_count) { 1 }
        let(:expected_attachable_type) { Job.name }
        let(:expected_attachable_id) { job.id }
        let(:valid_create_attachment_params) { { job_id: job.id, description: 'This is an attachment.' } }
        let(:expected_destroy_status) { :no_content }
      end
    end

    context 'when the attachable instance is an expense' do
      it_should_behave_like 'crud' do
        let(:user) { work_order.company.user }
        let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: expense) }
        let(:attachment_params)  { { id: attachment.id, job_id: job.id, expense_id: expense.id } }
        let(:expected_index_attachments_count) { 0 }
        let(:expected_attachable_type) { Expense.name }
        let(:expected_attachable_id) { expense.id }
        let(:valid_create_attachment_params) { { job_id: job.id, expense_id: expense.id, description: 'This is an attachment.' } }
        let(:expected_destroy_status) { :no_content }
      end
    end
  end

  context 'when the authenticated user is a provider' do
    let(:provider) { FactoryGirl.create(:provider, :with_user, company: company) }

    context 'when the attachable instance is a user' do
      it_should_behave_like 'crud' do
        let(:user) { provider.user }
        let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: user) }
        let(:attachment_params)  { { id: attachment.id, user_id: user.id } }
        let(:expected_index_attachments_count) { 1 }
        let(:expected_attachable_type) { User.name }
        let(:expected_attachable_id) { user.id }
        let(:valid_create_attachment_params) { { user_id: user.id, description: 'This is an attachment.' } }
        let(:expected_destroy_status) { :no_content }
      end
    end

    context 'when the attachable instance is a work order' do
      context 'when the provider is a work order provider' do
        before { work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]; work_order.save }

        it_should_behave_like 'crud' do
          let(:user) { provider.user }
          let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: work_order) }
          let(:attachment_params)  { { id: attachment.id, work_order_id: work_order.id } }
          let(:expected_index_attachments_count) { 1 }
          let(:expected_attachable_type) { WorkOrder.name }
          let(:expected_attachable_id) { work_order.id }
          let(:valid_create_attachment_params) { { work_order_id: work_order.id, description: 'This is an attachment.' } }
          let(:expected_destroy_status) { :forbidden }
        end
      end
    end

    context 'when the attachable instance is a job' do
      context 'when a supervisor on the job is the actor' do
        before { job.supervisors = [provider] }

        it_should_behave_like 'crud' do
          let(:user) { provider.user }
          let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: job) }
          let(:attachment_params)  { { id: attachment.id, job_id: job.id } }
          let(:expected_index_attachments_count) { 1 }
          let(:expected_attachable_type) { Job.name }
          let(:expected_attachable_id) { job.id }
          let(:valid_create_attachment_params) { { job_id: job.id, description: 'This is an attachment.' } }
          let(:expected_destroy_status) { :forbidden }
        end
      end

      context 'when a (non-supervising) provider on the job is the actor' do
        before do
          wo = job.work_orders.create(company: job.company,
                                      customer: FactoryGirl.create(:customer, company: job.company))
          wo.work_order_providers_attributes = [ { provider_id: provider.id } ]
        end

        it_should_behave_like 'crud' do
          let(:user) { provider.user }
          let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: job) }
          let(:attachment_params)  { { id: attachment.id, job_id: job.id } }
          let(:expected_index_attachments_count) { 1 }
          let(:expected_attachable_type) { Job.name }
          let(:expected_attachable_id) { job.id }
          let(:valid_create_attachment_params) { { job_id: job.id, description: 'This is an attachment.' } }
          let(:expected_destroy_status) { :forbidden }
        end
      end
    end

    context 'when the attachable instance is an expense' do
      context 'when the expensable is a job' do
        context 'when a supervisor on the job is the actor' do
          before { job.supervisors = [provider] }

          it_should_behave_like 'crud' do
            let(:user) { provider.user }
            let(:attachment) { FactoryGirl.create(:attachment, user: user, attachable: expense) }
            let(:attachment_params)  { { id: attachment.id, job_id: job.id, expense_id: expense.id } }
            let(:expected_index_attachments_count) { 0 }
            let(:expected_attachable_type) { Expense.name }
            let(:expected_attachable_id) { expense.id }
            let(:valid_create_attachment_params) { { job_id: job.id, expense_id: expense.id, description: 'This is an attachment.' } }
            let(:expected_destroy_status) { :forbidden }
          end
        end
      end

      context 'when the expensable is a work order' do
        let(:expense)    { FactoryGirl.create(:expense, expensable: work_order) }

        context 'when a provider on the work order is the actor' do
          before { work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]; work_order.save }

          before { sign_in provider.user }

          describe '#index' do
            before { get :index, work_order_id: work_order.id, expense_id: expense.id }

            it 'should return 200' do
              subject
              expect(response).to have_http_status(:ok)
            end

            it 'should render the index template' do
              subject
              expect(response).to render_template('index')
            end
          end

          describe'#create' do
            subject { post :create, work_order_id: work_order.id, expense_id: expense.id, description: 'This is an attachment.' }

            it 'creates a new attachment' do
              expect { subject }.to change(Attachment, :count).by(1)
            end

            it 'assigns a newly created attachment as @attachment' do
              subject
              expect(assigns(:attachment)).to be_a(Attachment)
              expect(assigns(:attachment)).to be_persisted
              expect(assigns(:attachment).attachable_type).to eq(Expense.name)
              expect(assigns(:attachment).attachable_id).to eq(expense.id)
            end

            it 'assigns the newly created attachment user' do
              subject
              expect(assigns(:attachment).user).to eq(provider.user)
            end

            it 'returns a 201 status code' do
              subject
              expect(response).to have_http_status(:created)
            end

            it 'should render the show template' do
              subject
              expect(response).to render_template('show')
            end
          end
        end
      end
    end
  end
end
