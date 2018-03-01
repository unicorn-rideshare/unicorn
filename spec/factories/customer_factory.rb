FactoryGirl.define do
  factory :customer do
    company
    contact_attributes { FactoryGirl.attributes_for(:contact, name: name || Faker::Name.name) }
    name { Faker::Name.name }

    trait :with_user do
      user
    end
  end
end
