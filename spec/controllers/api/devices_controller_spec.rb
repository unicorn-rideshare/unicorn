require 'rails_helper'

describe Api::DevicesController, api: true do
  let(:user)    { FactoryGirl.create(:user) }
  let(:device)  { FactoryGirl.create(:device, user: user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :show do
    let(:resource) { device }
  end
end
