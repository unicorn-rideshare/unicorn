FactoryGirl.define do
  factory :attachment do
    user
    attachable { FactoryGirl.create(:user) }
  end
end
