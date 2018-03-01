require 'rails_helper'

describe GeocodeContactJob do
  let(:contact) { FactoryGirl.create(:contact) }
  let(:latitude)  { 42.6998457 }
  let(:longitude) { -74.923244 }

  describe '.perform' do
    context 'contact is locatable' do
      before do
        allow(GeocodingService).to receive(:geocode).and_return([{ geometry: { location: { latitude: latitude, longitude: longitude } } }.with_indifferent_access])
        GeocodeContactJob.perform(contact.id)
        contact.reload
      end

      it 'should set the contact latitude' do
        expect(contact.latitude).to eq(latitude)
      end

      it 'should set the contact longitude' do
        expect(contact.longitude).to eq(longitude)
      end
    end

    context 'contact is not locatable' do
      let(:contact) { FactoryGirl.create(:contact, :unlocatable) }

      before do
        allow(GeocodingService).to receive(:geocode).and_return(nil)
        GeocodeContactJob.perform(contact.id)
        contact.reload
      end

      it 'should nil the contact latitude' do
        expect(contact.latitude).to be_nil
      end

      it 'should nil the contact longitude' do
        expect(contact.longitude).to be_nil
      end
    end
  end
end
