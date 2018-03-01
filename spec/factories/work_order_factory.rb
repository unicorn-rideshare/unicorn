FactoryGirl.define do
  factory :work_order do
    company
    customer { create(:customer, company: company) }

    transient do
      provider { create(:provider, :with_user, company: company) }
    end

    after(:build) do |work_order|
      if work_order.status.nil?
        work_order.status = :awaiting_schedule
        preferred_scheduled_start_date = (work_order.scheduled_start_at || DateTime.now + 5.days).to_date
        work_order.preferred_scheduled_start_date = preferred_scheduled_start_date unless work_order.preferred_scheduled_start_date
      end
    end

    trait :with_materials do
      after(:create) do |work_order|
        job = FactoryGirl.create(:job, :with_materials, company: work_order.company)
        job.work_orders << work_order
        job.materials.each do |job_product|
          work_order.materials.create(job_product: job_product)
        end
      end
    end

    trait :with_provider do
      after(:create) do |work_order, evaluator|
        provider_id = (evaluator.provider.id rescue evaluator.provider_id) rescue nil
        work_order.work_order_providers_attributes = [ { provider_id: provider_id } ]
      end
    end

    trait :awaiting_schedule do
      after(:build) do |work_order|
        preferred_scheduled_start_date = (work_order.scheduled_start_at || DateTime.now + 5.days).to_date
        work_order.preferred_scheduled_start_date = preferred_scheduled_start_date unless work_order.preferred_scheduled_start_date
      end
    end

    trait :abandoned do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
        work_order.abandon!
      end
    end

    trait :delayed do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now - 2.hours
        work_order.status = 'delayed'
        work_order.scheduled_start_at = scheduled_start_at
        work_order.due_at = scheduled_start_at + 2.hours
        work_order.save(validate: false)
      end
    end

    trait :scheduled do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
      end
    end

    trait :scheduled_with_due_at do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at, due_at: scheduled_start_at + 2.days)
      end
    end

    trait :en_route do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
        work_order.route!
      end
    end

    trait :in_progress do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
        work_order.start!
      end
    end

    trait :paused do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
        work_order.start!
        work_order.pause!
      end
    end

    trait :canceled do
      after(:create) do |work_order|
        work_order.cancel!
      end
    end

    trait :completed do
      after(:create) do |work_order|
        scheduled_start_at = work_order.scheduled_start_at || DateTime.now + 5.days
        work_order.scheduled_start_at = scheduled_start_at
        work_order.schedule! || work_order.update_attributes(status: 'scheduled', scheduled_start_at: scheduled_start_at)
        work_order.start!
        work_order.complete!
      end
    end
  end
end
