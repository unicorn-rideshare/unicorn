FactoryGirl.define do
  factory :provider_origin_assignment do
    after(:build) do |poa, evaluator|
      company = poa.provider ? poa.provider.company : FactoryGirl.create(:company)
      market = poa.origin ? poa.origin.market : FactoryGirl.create(:market, company: company)

      create_origin = poa.origin.nil?
      poa.origin = FactoryGirl.create(:origin, market: market) if create_origin

      create_provider = poa.provider.nil? || poa.provider.company_id != poa.origin.market.company_id
      poa.provider = FactoryGirl.create(:provider, company: market.company) if create_provider
    end

    trait :canceled do
      after(:create) do |poa|
        poa.cancel!
      end
    end

    trait :in_progress do
      after(:create) do |poa|
        poa.update_attribute(:scheduled_start_at, DateTime.now + 5.days)
        poa.clock_in!
      end
    end

    trait :completed do
      after(:create) do |poa|
        poa.update_attribute(:scheduled_start_at, DateTime.now + 5.days)
        poa.clock_in!
        poa.clock_out!
      end
    end
  end
end
