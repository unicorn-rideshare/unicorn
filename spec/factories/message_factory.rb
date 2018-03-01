FactoryGirl.define do
  factory :message do
    recipient { FactoryGirl.create(:user) }
    sender { FactoryGirl.create(:user) }
    body { Faker::Lorem.paragraph }
  end
end
