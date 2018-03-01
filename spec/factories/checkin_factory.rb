FactoryGirl.define do
  factory :checkin do
    checkin_at { Time.now.change(usec: 0) }
    latitude 37.09024
    longitude(-95.712891)
    locatable { FactoryGirl.create(:user) }
  end
end
