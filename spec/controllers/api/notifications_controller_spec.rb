require 'rails_helper'

describe Api::NotificationsController, api: true do
  let(:user)          { FactoryGirl.create(:user) }
  let(:notification)  { FactoryGirl.create(:notification, recipient: user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index do
    let(:resource) { notification }
  end
end
