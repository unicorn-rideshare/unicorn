shared_examples 'locatable' do
  it { should have_many(:checkins) }

  describe '#last_checkin' do
    let(:last_checkin) { FactoryGirl.create(:checkin, locatable: locatable) }

    before do
      Timecop.freeze(DateTime.now - 10.minutes)
      FactoryGirl.create(:checkin, locatable: locatable)
      Timecop.return

      last_checkin
    end

    it 'returns the most recent checkin' do
      expect(locatable.last_checkin).to eq(last_checkin)
    end
  end

  describe 'destroying the locatable' do
    let(:checkin)    { FactoryGirl.create(:checkin) }
    let(:locatable)  { checkin.locatable }

    before { expect(locatable.reload.checkins.size).to eq(1) }

    subject { locatable.destroy }

    it 'should destroy all of the checkins which belong to the destroyed locatable' do
      subject
      expect(locatable.checkins.size).to eq(0)
    end
  end
end
