require 'rails_helper'

describe Checkin do


  it { should belong_to(:locatable) }

  it { should validate_presence_of(:checkin_at) }

  it { should validate_numericality_of(:latitude) }
  it { should validate_numericality_of(:longitude) }

  describe 'default scope' do
    let!(:checkin_one) { FactoryGirl.create(:checkin, checkin_at: DateTime.now - 2.days) }
    let!(:checkin_two) { FactoryGirl.create(:checkin, checkin_at: DateTime.now) }

    it 'orders by checkin_at desc' do
      expect(Checkin.all.to_a).to eq([checkin_two, checkin_one])
    end
  end

  describe '#create' do
    let(:user) { FactoryGirl.create(:user) }

    it 'should set the :geom field on the checkin' do
      checkin = FactoryGirl.create(:checkin, locatable: user)
      expect(checkin.reload.geom).not_to be_nil
    end

    it 'should push a websocket :new event notification to subscribers on the locatable checkins' do
      channel = WebsocketRails["user_checkins_#{user.id}"]
      expect(channel).to receive(:trigger).with(:new, anything).exactly(1).times
      FactoryGirl.create(:checkin, locatable: user)
    end
  end

  describe '#valid?' do
    let(:checkin) { FactoryGirl.create(:checkin) }

    it 'should not allow the locatable_id to change' do
      new_user = FactoryGirl.create(:user)
      checkin.update_attributes(locatable: new_user) && true
      expect(checkin.errors[:locatable_id]).to include("can't be changed")
    end

    it 'should not allow the locatable_type to change' do
      checkin.update_attributes(locatable_type: 'NewType') && true
      expect(checkin.errors[:locatable_type]).to include("can't be changed")
    end
  end
end
