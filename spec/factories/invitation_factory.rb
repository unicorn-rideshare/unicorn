FactoryGirl.define do
  factory :invitation do
    sender    { FactoryGirl.create(:user) }
    invitable { FactoryGirl.create(:user) }

    trait :pin do
      after(:build) do |invitation|
        invitation.type = :pin
      end
    end

    trait :expired do
      after(:create) do |invitation, evaluator|
        expires_at = DateTime.now - [1, 2, 3, 4, 5].sample.hours
        invitation.update_attribute(:expires_at, expires_at)
      end
    end
  end
end
