FactoryGirl.define do
  factory :expense do
    user
    expensable { FactoryGirl.create(:job) }
  end
end
