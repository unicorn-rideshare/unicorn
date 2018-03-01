FactoryGirl.define do
  factory :category do
    company
    name  { Faker::Commerce.department }
  end
end
