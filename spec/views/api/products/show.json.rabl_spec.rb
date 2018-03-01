require 'rails_helper'

describe 'api/products/show' do
  let(:gtin)    { Faker::Code.ean }
  let(:product) { FactoryGirl.create(:product, gtin: gtin) }

  it 'should render product' do
    @product = product
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => product.id,
                                        'gtin' => gtin,
                                        'barcode_uri' => "data:image/png;base64,#{Base64.encode64(product.barcode_png).gsub(/\n/, '')}",
                                        'data' => {},
                                        'tier' => nil,
                                        'product_id' => nil,
                                    )
  end
end
