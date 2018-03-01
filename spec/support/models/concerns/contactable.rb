shared_examples 'contactable' do
  it { should have_one(:contact) }
  it { should accept_nested_attributes_for(:contact) }

  context 'update the contact' do
    it 'should update the contact' do
      expected_contact = contactable.contact
      contactable.update_attributes!(contact_attributes: { id: expected_contact.id,
                                                           name: Faker::Name.name, 
                                                           address1: '123 New St', 
                                                           time_zone_id: Faker::Address.time_zone })
      expect(contactable.contact.id).to eq(expected_contact.id)
    end
  end

  describe 'destroying the contactable' do
    let(:contact)      { contactable.contact }

    before { expect(contactable.reload.contact).to eq(contact) }

    subject { contactable.destroy }

    it 'should destroy the contact which belongs to the destroyed contactable' do
      subject
      expect(contactable.contact.destroyed?).to eq(true)
    end
  end
end
