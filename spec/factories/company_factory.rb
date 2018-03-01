FactoryGirl.define do
  factory :company do
    contact_attributes { FactoryGirl.attributes_for(:contact, name: name) }
    name { Faker::Company.name }
    user
  end
end
