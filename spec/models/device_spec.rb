require 'rails_helper'

describe Device do
  let(:device) { FactoryGirl.create(:device) }



  it { should belong_to(:user) }

  describe '#valid?' do
    it 'should not allow the user to change' do
      device.update_attributes(user: FactoryGirl.create(:user)) && true
      expect(device.errors[:user_id]).to include("can't be changed")
    end

    it 'should not allow the :apns_device_id and :gcm_registration_id to be set simultaneously' do
      device.update_attributes(apns_device_id: 'some-apns-id', gcm_registration_id: 'some-gcm-id') && true
      expect(device.errors[:apns_device_id]).to include("can't be set with gcm registration id")
      expect(device.errors[:gcm_registration_id]).to include("can't be set with apns device id")
    end
  end

  describe '#type' do
    context 'when no :apns_device_id or :gcm_registration_id is set' do
      it 'should return :unknown' do
        expect(device.type).to eq(:unknown)
      end
    end

    context 'when the :apns_device_id is set' do
      before { device.apns_device_id = 'some-apns-id' }

      it 'should return :ios' do
        expect(device.type).to eq(:ios)
      end
    end

    context 'when the :gcm_registration_id is set' do
      before { device.gcm_registration_id = 'some-gcm-registration-id' }

      it 'should return :android' do
        expect(device.type).to eq(:android)
      end
    end
  end
end
