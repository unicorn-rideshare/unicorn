shared_examples 'geocodable' do
  describe '#sanitize_address' do
    %w(address1 address2 city state zip).each do |address_attr|
      it "should sanitize the #{address_attr} address attribute if an empty string is given" do
        geocodable.update_attributes!(address_attr => ['', '    '].sample)
        expect(geocodable.reload.address2).to eq(nil)
      end
    end
  end
end
