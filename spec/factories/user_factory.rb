FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    password 'password'

    trait :with_contact do
      after(:create) do |user, evaluator|
        FactoryGirl.create(:contact, contactable: user)
      end
    end
  end
end
