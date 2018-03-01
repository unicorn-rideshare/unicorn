require 'rails_helper'

describe 'api/categories/show' do
  let(:category) { FactoryGirl.create(:category, name: 'Concrete', abbreviation: 'C', base_price: 4.99, capacity: 4) }

  it 'should render category' do
    @category = category
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => category.id,
                                        'name' => 'Concrete',
                                        'abbreviation' => 'C',
                                        'base_price' => 4.99,
                                        'capacity' => 4,
                                        'icon_image_url' => nil,
                                    )
  end
end
