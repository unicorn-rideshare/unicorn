require 'rails_helper'

describe RoutingService do

  describe '.driving_directions' do
    context 'when the driving eta is < 1 hour', vcr: { cassette_name: 'tourguide_api_calculate_route' } do
      it 'should return the driving routes in the json response' do
        expect(RoutingService.driving_directions([Coordinate.new(33.9253024, -84.385744200000005), Coordinate.new(33.925491000000001, -84.351815200000004)])['routes']).to_not be_nil
      end
    end
  end

  describe '.driving_eta' do
    context 'when the driving eta is < 1 hour', vcr: { cassette_name: 'tourguide_api_calculate_eta_lt_1_hour' } do

      it 'should return the total number of minutes' do
        expect(RoutingService.driving_eta([Coordinate.new(33.9253024, -84.385744200000005), Coordinate.new(33.925491000000001, -84.351815200000004)])).to eq(8.033334)
      end
    end

    context 'when the driving eta is > 1 hour', vcr: { cassette_name: 'tourguide_api_calculate_eta_gt_1_hour' } do
      it 'should convert the response into minutes' do
        expect(RoutingService.driving_eta([Coordinate.new(33.9253024, -84.385744200000005), Coordinate.new(38.003067000000001, -84.583686)])).to eq(380.86667)
      end
    end
  end
end
