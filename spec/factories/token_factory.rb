FactoryGirl.define do
  factory :token do
    token SecureRandom.uuid
    authenticable { FactoryGirl.create(:user) }

    trait :expired do
      after(:create) do |token, evaluator|
        expires_at = DateTime.now - [1, 2, 3, 4, 5].sample.hours
        token.update_attribute(:expires_at, expires_at)
      end
    end
  end
end
