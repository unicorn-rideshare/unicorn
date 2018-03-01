FactoryGirl.define do
  factory :dispatcher do
    company
    contact_attributes { FactoryGirl.attributes_for(:contact) }

    trait :with_user do
      user
    end

    trait :with_origin_assignment do
      after(:create) do |dispatcher, evaluator|
        market = create(:market, company: dispatcher.company)
        origin = create(:origin, market: market)
        origin_assignment = DispatcherOriginAssignment.new(origin: origin, start_date: Date.today, end_date: Date.today)
        dispatcher.origin_assignments << origin_assignment
      end
    end
  end
end
