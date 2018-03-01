FactoryGirl.define do
  factory :contact do
    name          { Faker::Name.name }
    address1      { Faker::Address.street_address }
    city          { Faker::Address.city }
    state         { Faker::Address.state }
    zip           { Faker::Address.zip }

    time_zone_id  { Faker::Address.time_zone }

    email         { Faker::Internet.email }
    phone         { Faker::PhoneNumber.phone_number }
    mobile        { Faker::PhoneNumber.cell_phone }

    after(:build) do |contact|
      contact.skip_geocode = true
    end

    trait :blank_address do
      address1 nil
      address2 nil
      city nil
      state nil
      zip nil
    end

    trait :unlocatable do
      address2 nil
      city nil
      state nil
      zip nil
    end
  end
end
