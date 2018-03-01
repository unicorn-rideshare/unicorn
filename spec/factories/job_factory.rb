FactoryGirl.define do
  factory :job do
    company
    customer { create(:customer, company: company) }
    type { %w(commercial residential punchlist).sample }

    trait :with_materials do
      after(:create) do |job|
        3.times do
          product = create(:product, company: job.company)
          job.materials.create(product: product)
        end
      end
    end
  end
end
