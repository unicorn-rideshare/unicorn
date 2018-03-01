FactoryGirl.define do
  factory :market do
    company
    name { Faker::Address.city }
  end
end
