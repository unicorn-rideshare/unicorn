FactoryGirl.define do
  factory :product do
    company
    gtin { Faker::Code.ean }
  end
end
