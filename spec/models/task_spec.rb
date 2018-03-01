require 'rails_helper'

describe Task do
  let(:task) { FactoryGirl.create(:task) }

  it_behaves_like 'attachable'
  it_behaves_like 'commentable'


  it { should belong_to(:company) }
  it { should belong_to(:task) }
  it { should belong_to(:user) }
  it { should belong_to(:provider) }
  it { should belong_to(:category) }
  it { should belong_to(:job) }
  it { should belong_to(:work_order) }

  describe '#valid?' do
    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      task.company = new_company
      task.valid?
      expect(task.errors[:company_id]).to include("can't be changed")
    end

    it 'should associate the task with a category that belongs to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, category: FactoryGirl.create(:category, company: company))
      task.valid?
      expect(task.errors[:base]).to_not include(I18n.t('errors.messages.task_company_category_confirmation'))
    end

    it 'should not associate the task with a category that does not belong to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, category: FactoryGirl.create(:category))
      task.valid?
      expect(task.errors[:base]).to include(I18n.t('errors.messages.task_company_category_confirmation'))
    end

    it 'should associate the task with a job that belongs to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, job: FactoryGirl.create(:job, company: company))
      task.valid?
      expect(task.errors[:base]).to_not include(I18n.t('errors.messages.task_company_job_confirmation'))
    end

    it 'should not associate the task with a job that does not belong to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, job: FactoryGirl.create(:job))
      task.valid?
      expect(task.errors[:base]).to include(I18n.t('errors.messages.task_company_job_confirmation'))
    end

    it 'should associate the task with a work_order that belongs to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, work_order: FactoryGirl.create(:work_order, company: company))
      task.valid?
      expect(task.errors[:base]).to_not include(I18n.t('errors.messages.task_company_work_order_confirmation'))
    end

    it 'should not associate the task with a work_order that does not belong to its company' do
      company = FactoryGirl.create(:company)
      task = Task.new(company: company, work_order: FactoryGirl.create(:work_order))
      task.valid?
      expect(task.errors[:base]).to include(I18n.t('errors.messages.task_company_work_order_confirmation'))
    end

    context 'due_at' do
      it 'should not allow the task :due_at to be set in the past' do
        task.due_at = DateTime.now - 1.minute
        task.valid?
        expect(task.errors[:due_at]).to include("can't be in the past")
      end
    end
  end

  describe '#delegate' do
    before { task }

    context 'when a :task_id is provided' do
      context 'when the :user_id of the new task is the provider on the task specified by the :task_id' do
        context 'when the :provider to which the task is being delegated belongs to the task company' do
          let(:provider_delegate) { FactoryGirl.create(:provider, :with_user, company: task.company) }
          subject { task.delegate(provider_delegate) }

          it 'should delegate the task specified by the :task_id to the :provider_id' do
            expect { subject }.to change { Task.count }.by(1)
            expect(subject.reload.user).to eq(provider_delegate.user)
            expect(subject.reload.provider).to eq(provider_delegate)
          end
        end

        context 'when the :provider to which the task is being delegated does not belong to the task company' do
          subject { task.delegate(FactoryGirl.create(:provider)) }

          it 'not pass validation' do
            expect(subject.errors[:base]).to include(I18n.t('errors.messages.task_delegation_must_remain_in_task_company'))
          end
        end
      end
    end
  end

  describe '#past_due?' do
    context 'when the :due_at timestamp is nil' do
      let(:task) { FactoryGirl.create(:task, due_at: nil) }

      subject { task.past_due? }

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the :due_at timestamp is in the future' do
      let(:task) { FactoryGirl.create(:task, due_at: DateTime.now + 12.seconds) }

      subject { task.past_due? }

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the :due_at timestamp is in the past' do
      before { task.update_attribute(:due_at, DateTime.now - 12.minutes) }

      subject { task.past_due? }

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe 'state machine' do
    describe '#complete' do
      subject { task.complete! }

      context 'when the task status is :incomplete' do
        before { expect(task.reload.status.underscore.to_sym).to eq(:incomplete) }

        context 'when the task is a delegate' do
          let(:task) { FactoryGirl.create(:task, :delegate) }

          it 'should not allow the task to be completed' do
            subject
            expect(task.reload.completed?).to eq(false)
          end
        end

        context 'when the task is not a delegate' do
          it 'should allow the task to be completed' do
            subject
            expect(task.reload.completed?).to eq(true)
          end
        end
      end

      context 'when the task status is :pending_completion' do
        before { task.close!; expect(task.reload.status.underscore.to_sym).to eq(:pending_completion) }

        context 'when the task is a delegate' do
          let(:task) { FactoryGirl.create(:task, :delegate) }

          it 'should allow the task to be completed' do
            subject
            expect(task.reload.completed?).to eq(true)
          end
        end

        context 'when the task is not a delegate' do
          it 'should allow the task to be completed' do
            subject
            expect(task.reload.completed?).to eq(true)
          end
        end
      end
    end
  end

  describe 'delegation' do
    let(:company)   { FactoryGirl.create(:company) }
    let(:provider)  { FactoryGirl.create(:provider, :with_user, company: company) }
    let(:task)      { FactoryGirl.create(:task, company: company, provider_id: provider.id) }

    context 'when the task is created with a :provider_id' do
      before { allow(Resque).to receive(:enqueue).with(anything, anything) }

      subject { task }

      it 'should enqueue a TaskDelegationJob' do
        subject
        expect(Resque).to have_received(:enqueue).with(PushTaskDelegationNotificationsJob, anything)
      end
    end
  end
end
