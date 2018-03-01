FactoryGirl.define do
  factory :route do
    after(:build) do |route, evaluator|
      route.company = route.dispatcher_origin_assignment ? route.dispatcher_origin_assignment.dispatcher.company : (route.provider_origin_assignment ? route.provider_origin_assignment.provider.company : FactoryGirl.create(:company))
      route.date = route.date || (route.dispatcher_origin_assignment ? route.dispatcher_origin_assignment.start_date : (route.provider_origin_assignment ? route.provider_origin_assignment.start_date : Date.today))
      route.dispatcher_origin_assignment ||= evaluator.dispatcher_origin_assignment || FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: FactoryGirl.create(:dispatcher, company: route.company), start_date: route.date, end_date: route.date)
      route.provider_origin_assignment ||= evaluator.provider_origin_assignment || FactoryGirl.create(:provider_origin_assignment, provider: FactoryGirl.create(:provider, company: route.company), start_date: route.date, end_date: route.date)
    end

    trait :scheduled do
      after(:create) do |route|
        route.scheduled_start_at = DateTime.now + 5.days unless route.scheduled_start_at
        route.schedule!
      end
    end

    trait :loading do
      after(:create) do |route|
        route.scheduled_start_at = DateTime.now + 5.days unless route.scheduled_start_at
        route.schedule!
        route.load!
      end
    end

    trait :in_progress do
      after(:create) do |route|
        route.scheduled_start_at = DateTime.now + 5.days unless route.scheduled_start_at
        route.schedule!
        route.load!
        route.start!
      end
    end

    trait :with_dispatcher_origin_assignment do
      after(:build) do |route, evaluator|
        dispatcher = create(:dispatcher, :with_user)
        market = create(:market, company: dispatcher.company)
        origin = create(:origin, market: market)
        dispatcher.origin_assignments.create(origin: origin)
        route.dispatcher_origin_assignment = dispatcher.origin_assignments.first
      end
    end

    trait :with_provider_origin_assignment do
      after(:build) do |route, evaluator|
        provider = create(:provider, :with_user)
        market = create(:market, company: provider.company)
        origin = create(:origin, market: market)
        provider.origin_assignments.create(origin: origin)
        route.provider_origin_assignment = provider.origin_assignments.first
      end
    end

    trait :with_work_orders_and_items_ordered do
      after(:create) do |route, evaluator|
        provider_origin_assignment = route.provider_origin_assignment
        company = provider_origin_assignment.provider.company

        product1 = FactoryGirl.create(:product, company: company)
        product2 = FactoryGirl.create(:product, company: company)
        product3 = FactoryGirl.create(:product, company: company)

        3.times do
          wo = FactoryGirl.create(:work_order, company: company)
          route.legs.create(work_order: wo)
          [product1, product2, product3].shuffle.each do |product|
            wo.items_ordered << product
          end
        end
      end
    end
  end
end
