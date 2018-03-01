FactoryGirl.define do
  factory :provider do
    company
    contact_attributes { FactoryGirl.attributes_for(:contact) }

    trait :with_user do
      user
    end

    trait :with_origin_assignment do
      after(:create) do |provider, evaluator|
        market = create(:market, company: provider.company)
        origin = create(:origin, market: market)
        origin.provider_origin_assignments.create(provider: provider, start_date: Date.today, end_date: Date.today)
      end
    end
  end
end
