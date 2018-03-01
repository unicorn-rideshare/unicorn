FactoryGirl.define do
  factory :notification do
    notifiable { FactoryGirl.create(:user) }
    recipient { FactoryGirl.create(:user) }
    type { %w().sample }
    slug { Faker::Code.ean }
  end
end
