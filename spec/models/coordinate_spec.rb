require 'rails_helper'

describe Coordinate do
  let(:coordinate) { Coordinate.new(33.9253024, -84.385744200000005) }

  describe '#==' do
    it 'should return true when an identical coordinate is provided' do
      expect(coordinate == Coordinate.new(33.9253024, -84.385744200000005)).to eq(true)
    end

    it 'should return false when an different coordinate is provided' do
      expect(coordinate == Coordinate.new(33.925491, -84.3518152)).to eq(false)
    end
  end

  describe '#hash' do
    it 'should return the hash of an array representation of the lat/long' do
      expect(coordinate.hash).to eq([33.9253024, -84.385744200000005].hash)
    end
  end

  describe '#to_s' do
    it 'should return a string representation of the lat/long' do
      expect(coordinate.to_s).to eq('33.9253024,-84.3857442')
    end
  end
end
