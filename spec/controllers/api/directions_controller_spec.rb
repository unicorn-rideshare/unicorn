require 'rails_helper'

describe Api::DirectionsController, api: true do
  let(:user)  { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  describe '#index' do
    context 'with valid params', vcr: { cassette_name: 'tourguide_api_calculate_route' } do
      let(:params) { { from_latitude: 33.9253024, from_longitude: -84.385744200000005, to_latitude: 33.925491000000001, to_longitude: -84.351815200000004 } }

      subject { get :index, params }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'returns valid json' do
        subject
        expect(JSON.parse(response.body)).to_not be_nil
      end
    end

    context 'with invalid params' do
      subject { get :index, {} }

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(400)
      end
    end
  end

  describe '#eta' do
    context 'with valid params', vcr: { cassette_name: 'tourguide_api_calculate_eta_lt_1_hour' } do
      let(:params) { { from_latitude: 33.9253024, from_longitude: -84.385744200000005, to_latitude: 33.925491000000001, to_longitude: -84.351815200000004 } }

      subject { get :eta, params }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'returns valid json' do
        subject
        expect(JSON.parse(response.body)).to_not be_nil
      end
    end

    context 'with invalid params' do
      subject { get :eta, {} }

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(400)
      end
    end
  end
end
