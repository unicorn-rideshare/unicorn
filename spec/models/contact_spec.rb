require 'rails_helper'

describe Contact do
  it_behaves_like 'geocodable'


  before { subject.contactable = FactoryGirl.create(:user) }

  let(:geocodable) { FactoryGirl.create(:contact) }

  it { should belong_to(:contactable) }
  it { should validate_uniqueness_of(:contactable_id).scoped_to(:contactable_type).allow_nil }

  it { should respond_to(:name) }
  it { should validate_presence_of(:name) }

  context 'when the contactable requires the presence of a time zone' do        
    it 'should validate the :time_zone_id' do
      allow(subject.contactable).to receive(:require_contact_time_zone?) { true }
      subject.valid?
      expect(subject.errors[:time_zone_id]).to eq(['Contact time zone can\'t be blank'])
    end
    
    it 'should validate the :time_zone' do
      allow(subject.contactable).to receive(:require_contact_time_zone?) { true }
      subject.valid?
      expect(subject.errors[:time_zone]).to eq(['Contact time zone can\'t be blank'])
    end
  end

  it { should respond_to(:email) }
  it { should respond_to(:phone) }
  it { should respond_to(:mobile) }
  it { should respond_to(:fax) }

  it { should respond_to(:address1) }
  it { should respond_to(:address2) }
  it { should respond_to(:city) }
  it { should respond_to(:state) }
  it { should respond_to(:zip) }

  describe '#valid?' do
    let(:contactable) { FactoryGirl.create(:user, :with_contact) }
    let(:contact) { contactable.contact }

    it 'should not allow the contactable id to change' do
      contact.contactable_id = nil
      contact.valid?
      expect(contact.errors[:contactable_id]).to include("can't be changed")
    end

    it 'should not allow the contactable type to change' do
      new_contactable = FactoryGirl.create(:company)
      contact.update_attributes(contactable: new_contactable) && true
      expect(contact.errors[:contactable_type]).to include("can't be changed")
    end

    it 'should not allow the latitude to change' do
      contact.latitude = -1
      contact.valid?
      expect(contact.errors[:latitude]).to include("can't be changed")
    end

    it 'should not allow the longitude to change' do
      contact.longitude = -1
      contact.valid?
      expect(contact.errors[:longitude]).to include("can't be changed")
    end
  end

  describe '#schedule_geocode!' do
    let(:contact) { FactoryGirl.create(:contact) }

    it 'should be called when a new contact is created' do
      contact = FactoryGirl.build(:contact, address1: '123 Test St')
      expect(contact).to receive(:schedule_geocode).once
      contact.save!
    end

    it 'should be called when an existing contact is updated' do
      expect(contact).to receive(:schedule_geocode).once
      contact.update_attributes! address1: '123 Test St'
    end

    it 'should schedule a geocode contact job' do
      c = FactoryGirl.build :contact
      c.id = 1
      c.save!
      expect(GeocodeContactJob).to have_queued(1)
    end
  end

  describe '#first_name' do
    let(:contact) { FactoryGirl.create(:contact, name: 'Joe User') }

    it 'should return only the first name without whitespace' do
      expect(contact.first_name).to eq('Joe')
    end
  end

  describe '#last_name' do
    context 'when the contact name does not contain whitespace' do
      let(:contact) { FactoryGirl.create(:contact, name: 'Joe') }

      it 'should return nil' do
        expect(contact.last_name).to be_nil
      end
    end

    context 'when the contact name contains whitespace' do
      let(:contact) { FactoryGirl.create(:contact, name: 'Joe Von User') }

      it 'should return only the last name without whitespace' do
        expect(contact.last_name).to eq('User')
      end
    end
  end

  describe '#coordinate' do
    let(:contact) { FactoryGirl.create(:contact) }

    context 'when the latitude and longitude are nil' do
      it 'should return nil' do
        expect(contact.coordinate).to be_nil
      end
    end

    context 'when the latitude and longitude are not nil' do
      let(:latitude)  { BigDecimal('33.9253024') }
      let(:longitude) { BigDecimal('-84.3857442') }

      before do
        contact.latitude = latitude
        contact.longitude = longitude
      end

      it 'should return a coordinate' do
        expect(contact.coordinate).to be_a(Coordinate)
      end

      it 'should return a coordinate with properly populated lat/long' do
        expect(contact.coordinate.to_s).to eq('33.9253024,-84.3857442')
      end
    end

  end
end
