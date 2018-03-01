require 'rails_helper'

describe 'api/notifications/show' do
  let(:notification) { FactoryGirl.create(:notification) }

  it 'should render notifications' do
    @notification = notification
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => notification.id,
                                        'recipient_id' => notification.recipient_id,
                                        'slug' => notification.slug,
                                        'type' => nil,
                                        'delivered_at' => nil,
                                        'suppressed_at' => nil,
                                    )
  end
end
