require 'rails_helper'

describe Api::RouteLegsController, api: true do
  let(:user)                        { FactoryGirl.create(:user) }
  let(:company)                     { FactoryGirl.create(:company, user: user) }
  let(:provider_user)               { FactoryGirl.create(:user) }
  let(:provider)                    { FactoryGirl.create(:provider, company: company, user: provider_user) }
  let(:market)                      { FactoryGirl.create(:market, company: company) }
  let(:provider_origin_assignment)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: FactoryGirl.create(:origin, market: market), start_date: Date.today, end_date: Date.today) }
  let(:route)                       { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment) }
  let(:route_leg)                   { FactoryGirl.create(:route_leg, route: route) }

  before do
    sign_in user
  end

  it_behaves_like 'api_controller', :index, :update do
    let(:resource) { route_leg }
    let(:resource_params) { { route_id: route.id, id: route_leg.id } }
  end
end
