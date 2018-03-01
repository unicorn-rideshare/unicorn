require 'rails_helper'

describe Api::TimeZonesController, api: true do
  let(:user) { FactoryGirl.create(:user) }

  describe 'GET index' do
    before do
      sign_in user
      get :index
    end

    it 'assigns all resource collection' do
      expect(assigns(:time_zones)).to eq(TimeZone.all)
    end

    it { should respond_with(:ok) }
    it { should render_template('index') }
  end
end
