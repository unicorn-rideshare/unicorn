require 'rails_helper'

describe Api::TasksController, api: true do
  let(:user)     { FactoryGirl.create(:user) }
  let(:company)  { FactoryGirl.create(:company, user: user) }
  let(:category) { FactoryGirl.create(:category, company: company) }
  let(:task)      { FactoryGirl.create(:task, company: company) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :destroy do
    let(:resource) { task }
  end

  describe 'POST create' do
    describe 'with valid params' do
      subject { post :create, company_id: company.id, category_id: category.id, name: 'my task' }

      it 'creates a new Task' do
        expect { subject }.to change(Task, :count).by(1)
      end

      it 'assigns a newly created task as @task' do
        subject
        expect(assigns(:task)).to be_a(Task)
        expect(assigns(:task)).to be_persisted
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
      subject { post :create, company_id: FactoryGirl.create(:company).id, name: 'my task' }

      it 'assigns a newly created but unsaved task as @task' do
        subject
        expect(assigns(:task)).to be_a_new(Task)
      end

      it 'returns a 403 status code' do
        subject
        expect(response).to have_http_status(403)
      end
    end

    describe 'with invalid category id' do
      subject { post :create, name: 'my task', company_id: company.id, category_id: FactoryGirl.create(:category).id }

      it 'assigns a newly created but unsaved task as @task' do
        subject
        expect(assigns(:task)).to be_a_new(Task)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end
    end
  end
end
