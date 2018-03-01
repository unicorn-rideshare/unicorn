require 'rails_helper'

describe Product do
  let(:product) { FactoryGirl.create(:product) }

  it_behaves_like 'attachable'

  it { should belong_to(:company) }
  it { should validate_presence_of(:company) }

  it { should have_and_belong_to_many(:orders) }
  it { should have_and_belong_to_many(:deliveries) }
  it { should have_and_belong_to_many(:rejections) }

  describe '#valid?' do
    it 'should not allow the company to change' do
      new_company = FactoryGirl.create(:company)
      product.update_attributes(company: new_company) && true
      expect(product.errors[:company_id]).to include("can't be changed")
    end
  end

  describe '#save' do
    before { product }

    context 'when the gtin has been changed' do
      context 'when the gtin is an EAN13' do
        let(:new_gtin)    { Faker::Code.ean }
        let(:barcode_png) { Barby::EAN13.new(new_gtin[0..11]).to_png }

        before do
          product.gtin = new_gtin
          product.save
        end

        it 'should set the barcode_uri' do
          expect(product.reload.barcode_uri).to eq("data:image/png;base64,#{Base64.encode64(barcode_png).gsub(/\n/, '')}")
        end
      end

      context 'when the gtin can be represented as Code39' do
        let(:new_gtin)    { 'V000028020' }
        let(:barcode_png) { Barby::Code39.new(new_gtin).to_png }

        before do
          product.gtin = new_gtin
          product.save
        end

        it 'should set the barcode_uri' do
          expect(product.reload.barcode_uri).to eq("data:image/png;base64,#{Base64.encode64(barcode_png).gsub(/\n/, '')}")
        end
      end
    end
  end

  describe '#barcode_png' do
    let(:gtin)        { Faker::Code.ean }
    let(:barcode_png) { Barby::EAN13.new(gtin[0..11]).to_png }

    let(:product) { FactoryGirl.create(:product, gtin: gtin) }

    context 'when the gtin is valid EAN13 code' do
      it 'should return a valid png' do
        expect(product.barcode_png).to eq(barcode_png)
      end
    end
  end
end
