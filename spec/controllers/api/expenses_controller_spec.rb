require 'rails_helper'

describe Api::ExpensesController, api: true do
  let(:user)    { FactoryGirl.create(:user) }

  before { sign_in user }

  context 'when the expensable is a job' do
    let(:user)    { job.company.user }
    let(:job)     { FactoryGirl.create(:job) }
    let(:expense) { FactoryGirl.create(:expense, expensable: job) }

    describe '#index' do
      before do
        get :index, job_id: job.id
      end

      it_behaves_like 'a successful index request'
    end

    describe 'POST create' do
      describe 'with valid params' do
        subject { post :create, job_id: job.id }

        it 'creates a new expense' do
          expect { subject }.to change(Expense, :count).by(1)
        end

        it 'assigns a newly created expense as @expense' do
          subject
          expect(assigns(:expense)).to be_a(Expense)
          expect(assigns(:expense)).to be_persisted
        end

        it 'assigns the newly created expense user' do
          subject
          expect(assigns(:expense).user).to eq(user)
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

  context 'when the expensable is a work order' do
    let(:user)        { work_order.company.user }
    let(:work_order)  { FactoryGirl.create(:work_order) }
    let(:expense)     { FactoryGirl.create(:expense, expensable: work_order) }

    describe '#index' do
      before do
        get :index, work_order_id: work_order.id
      end

      it_behaves_like 'a successful index request'
    end

    describe 'POST create' do
      describe 'with valid params' do
        subject { post :create, work_order_id: work_order.id }

        it 'creates a new expense' do
          expect { subject }.to change(Expense, :count).by(1)
        end

        it 'assigns a newly created expense as @expense' do
          subject
          expect(assigns(:expense)).to be_a(Expense)
          expect(assigns(:expense)).to be_persisted
        end

        it 'assigns the newly created expense user' do
          subject
          expect(assigns(:expense).user).to eq(user)
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
