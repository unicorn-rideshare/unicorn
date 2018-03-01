FactoryGirl.define do
  factory :dispatcher_origin_assignment do
    after(:build) do |doa, evaluator|
      company = doa.dispatcher ? doa.dispatcher.company : FactoryGirl.create(:company)
      market = doa.origin ? doa.origin.market : FactoryGirl.create(:market, company: company)

      create_origin = doa.origin.nil?
      doa.origin = FactoryGirl.create(:origin, market: market) if create_origin

      create_dispatcher = doa.dispatcher.nil? || doa.dispatcher.company_id != doa.origin.market.company_id
      doa.dispatcher = FactoryGirl.create(:dispatcher, company: market.company) if create_dispatcher
    end
  end
end
