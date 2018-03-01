FactoryGirl.define do
  factory :origin do
    market
    contact_attributes { FactoryGirl.attributes_for(:contact) }
  end
end
