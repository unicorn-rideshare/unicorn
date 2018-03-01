FactoryGirl.define do
  factory :task do
    user
    company
    category   { create(:category, company: company) }
    name       { Faker::Hacker.say_something_smart }

    trait(:delegate) do
      after(:create) do |task|
        provider = FactoryGirl.create(:provider, :with_user, company: task.company)
        task.delegate(provider)
      end
    end
  end
end
