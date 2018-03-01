require 'rails_helper'

describe Job do
  let(:job) { FactoryGirl.create(:job) }

  it_behaves_like 'attachable'
  it_behaves_like 'commentable'
  it_behaves_like 'expensable'
  it_behaves_like 'notifiable'

  it { should belong_to(:company) }

  it { should have_many(:tasks) }

  it { should have_and_belong_to_many(:work_orders) }

  describe '#create' do
    it 'should set the :started_at timestamp on the job' do # in the future, this will be set after bidding/planning
      expect(job.started_at).not_to be_nil
    end

    describe 'wizard mode' do
      it 'should set :wizard_mode on the job to true' do
        expect(job.wizard_mode).to eq(true)
      end
    end
  end

  describe '#valid?' do
    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      job.company = new_company
      job.valid?
      expect(job.errors[:company_id]).to include("can't be changed")
    end

    it 'should not allow the customer to change' do
      new_customer = FactoryGirl.create(:customer)
      job.customer = new_customer
      job.valid?
      expect(job.errors[:customer_id]).to include("can't be changed")
    end
  end

  describe 'state machine' do
    before do
      2.times { job.work_orders.create(customer: FactoryGirl.create(:customer, company: job.company)) }
    end

    describe '#cancel!' do
      it 'should set the :canceled_at timestamp on the job' do
        expect(job.canceled_at).to be_nil
        job.cancel!
        expect(job.canceled_at).not_to be_nil
      end

      it 'should ensure all work orders on the job are disposed of' do
        job.cancel!
        job.work_orders.each do |wo|
          expect(wo.status).to eq('canceled')
        end
      end
    end

    describe '#close!' do
      it 'should set the :job_duration timestamp on the job' do
        expect(job.job_duration).to be_nil
        job.close!
        expect(job.job_duration).not_to be_nil
      end

      #it 'should ensure all work orders on the job are disposed of'
    end

    describe '#complete!' do
      before { job.start! }

      it 'should set the :duration timestamp on the job' do
        expect(job.duration).to be_nil
        job.complete!
        expect(job.duration).not_to be_nil
      end

      context 'when a :job_duration timestamp is not set on the job' do
        it 'should set the :job_duration timestamp on the job' do
          expect(job.job_duration).to be_nil
          job.complete!
          expect(job.job_duration).not_to be_nil
        end
      end

      context 'when a :job_duration timestamp is already set on the job' do
        before { job.close! }

        it 'should not change the :job_duration timestamp on the job' do
          job_duration = job.job_duration
          job.complete!
          expect(job.reload.job_duration).to eq(job_duration)
        end
      end

      it 'should ensure the :job_duration timestamp is set on the job' do
        expect(job.job_duration).to be_nil
        job.complete!
        expect(job.job_duration).not_to be_nil
      end

      #it 'should ensure all work orders on the job are disposed of'
    end
  end

  describe 'work orders' do
    context 'when a work order is added' do
      let(:provider)   { FactoryGirl.create(:provider, :with_user, company: job.company) }
      let(:work_order) { FactoryGirl.create(:work_order, :with_provider, provider: provider, company: job.company) }

      subject { job.work_orders << work_order }

      it 'should add the :provider role to the provider user added to the job' do
        expect(provider.user.has_role?(:provider, job)).to eq(false)
        subject
        expect(provider.user.has_role?(:provider, job)).to eq(true)
      end
    end

    context 'when a work order is removed' do
      let(:provider)   { FactoryGirl.create(:provider, :with_user, company: job.company) }
      let(:work_order) { FactoryGirl.create(:work_order, :with_provider, provider: provider, company: job.company) }

      before { job.work_orders << work_order }
      subject { job.work_orders = job.work_orders.to_a.reject { |wo| wo.id == work_order.id } }

      context 'when the removed provider is also a supervisor on the job' do
        before { job.supervisors = [provider] }

        it 'should not remove the :provider role from the provider user associated with the removed work order' do
          expect(provider.user.has_role?(:provider, job)).to eq(true)
          subject
          expect(provider.user.has_role?(:provider, job)).to eq(true)
        end
      end

      context 'when the removed provider is not a supervisor on the job' do
        it 'should remove the :provider role from the provider user removed from the job' do
          expect(provider.user.has_role?(:provider, job)).to eq(true)
          subject
          expect(provider.user.has_role?(:provider, job)).to eq(false)
        end
      end
    end
  end

  describe 'supervisors' do
    let(:provider1) { FactoryGirl.create(:provider, :with_user, company: job.company) }
    let(:provider2) { FactoryGirl.create(:provider, :with_user, company: job.company) }

    context 'when there are supervisors added' do
      subject { job.supervisors = [provider1] }

      it 'should add the :supervisor role to the provider user for the job' do
        subject
        expect(provider1.user.has_role?(:supervisor, job)).to eq(true)
      end
    end

    context 'when there are supervisors removed' do
      before { job.supervisors = [provider1] }
      subject { job.supervisors = [provider2] }

      context 'when the removed supervisor is also associated with an existing work order on the job' do
        let(:work_order) { FactoryGirl.create(:work_order, :with_provider, provider: provider1, company: job.company) }

        before { job.work_orders << work_order }

        it 'should remove the :supervisor role from the removed provider user for the job' do
          expect(provider1.user.has_role?(:supervisor, job)).to eq(true)
          subject
          expect(provider1.user.has_role?(:supervisor, job)).to eq(false)
        end
      end

      context 'when the removed supervisor is not associated with any existing work order on the job' do
        it 'should remove the :supervisor role from the removed provider user for the job' do
          expect(provider1.user.has_role?(:supervisor, job)).to eq(true)
          subject
          expect(provider1.user.has_role?(:supervisor, job)).to eq(false)
        end
      end


      it 'should add the :supervisor role to the added provider user for the job' do
        subject
        expect(provider2.user.has_role?(:supervisor, job)).to eq(true)
      end
    end
  end

  describe 'providers' do
    let(:provider1) { FactoryGirl.create(:provider, :with_user, company: job.company) }
    let(:provider2) { FactoryGirl.create(:provider, :with_user, company: job.company) }

    context 'when a work order is added' do
      subject { job.work_orders.create(company: job.company,
                                       customer: FactoryGirl.create(:customer, company: job.company),
                                       work_order_providers_attributes: [{ provider_id: provider1.id }]) }

      it 'should add the :provider role to the provider user for the job' do
        expect(provider1.user.has_role?(:provider, job)).to eq(false)
        subject
        expect(provider1.user.has_role?(:provider, job)).to eq(true)
      end
    end

    context 'when a work order is removed' do
      let(:removed_work_order) { job.work_orders.create(company: job.company,
                                                        customer: FactoryGirl.create(:customer, company: job.company),
                                                        work_order_providers_attributes: [{ provider_id: provider1.id }]) }

      let(:kept_work_order)    { job.work_orders.create(company: job.company,
                                                        customer: FactoryGirl.create(:customer, company: job.company),
                                                        work_order_providers_attributes: [{ provider_id: provider1.id }]) }

      before { removed_work_order && kept_work_order }

      subject { job.work_orders = [kept_work_order] }

      context 'when the provider remains a provider on other job work orders' do
        it 'should not remove the :provider role from the removed provider user for the job' do
          expect(provider1.user.has_role?(:provider, job)).to eq(true)
          subject
          expect(provider1.user.has_role?(:provider, job)).to eq(true)
        end
      end

      context 'when the provider is no longer a provider on other job work orders' do
        let(:kept_work_order)    { job.work_orders.create(company: job.company,
                                                          customer: FactoryGirl.create(:customer, company: job.company),
                                                          work_order_providers_attributes: [{ provider_id: FactoryGirl.create(:provider, :with_user, company: job.company).id }]) }

        it 'should remove the :provider role from the removed provider user for the job' do
          expect(provider1.user.has_role?(:provider, job)).to eq(true)
          subject
          expect(provider1.user.has_role?(:provider, job)).to eq(false)
        end
      end
    end
  end

  describe 'contract_revenue' do
    context 'when the :quoted_price_per_sq_ft and :total_sq_ft are nil' do
      let(:job) { FactoryGirl.create(:job, quoted_price_per_sq_ft: nil, total_sq_ft: nil) }

      it 'should return nil' do
        expect(job.contract_revenue).to eq(0.0)
      end
    end

    context 'when the :quoted_price_per_sq_ft is changed' do
      let(:job) { FactoryGirl.create(:job, total_sq_ft: 200000) }

      subject { job.update_attribute(:quoted_price_per_sq_ft, 12.00) }

      it 'should update :contract_revenue' do
        subject
        expect(job.reload.contract_revenue).to eq(2400000)
      end
    end

    context 'when the :total_sq_ft is changed' do
      let(:job) { FactoryGirl.create(:job, quoted_price_per_sq_ft: 9.00) }

      subject { job.update_attribute(:total_sq_ft, 100.93) }

      it 'should update :contract_revenue' do
        subject
        expect(job.reload.contract_revenue).to eq(908.37)
      end
    end
  end

  describe 'cost' do
    context 'when :expensed_amount, :labor_cost and :materials_cost are all 0' do
      let(:job) { FactoryGirl.create(:job) }

      it 'should return 0' do
        expect(job.cost).to eq(0.0)
      end
    end
  end

  describe 'profit' do
    context 'when :contract_revenue is nil' do
      let(:job) { FactoryGirl.create(:job, contract_revenue: nil) }

      it 'should return nil' do
        expect(job.profit).to eq(0.0)
      end
    end
  end
end
