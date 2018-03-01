require 'rails_helper'

describe 'api/attachments/show' do
  let(:user)  { FactoryGirl.create(:user) }
  let(:attachment) { FactoryGirl.create(:attachment,
                                        user: user,
                                        latitude: 90.0,
                                        longitude: 120.0,
                                        description: 'the description',
                                        key: 'development/somekey',
                                        mime_type: 'image/jpg',
                                        public: false,
                                        tags: %w(test image),
                                        url: 'https://s3.amazonaws.com/api.images/development/somekey') }

  it 'should render attachment' do
    @attachment = attachment
    @include_user = true
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => attachment.id,
                                        'attachable_type' => 'user',
                                        'attachable_id' => attachment.attachable_id,
                                        'created_at' => attachment.created_at.iso8601,
                                        'parent_attachment_id' => nil,
                                        'description' => 'the description',
                                        'latitude' => 90.0,
                                        'longitude' => 120.0,
                                        'key' => 'development/somekey',
                                        'metadata' => {},
                                        'mime_type' => 'image/jpg',
                                        'public' => false,
                                        'status' => 'published',
                                        'tags' => %w(test image),
                                        'url' => 'https://s3.amazonaws.com/api.images/development/somekey',
                                        'display_url' => nil,
                                        'user_id' => user.id,
                                        'user' => {
                                            'id' => user.id,
                                            'name' => user.name,
                                            'email' => user.email,
                                            'profile_image_url' => user.profile_image_url,
                                            'company_ids' => [],
                                            'provider_ids' => [],
                                            'default_company_id' => nil,
                                            'last_checkin_latitude' => nil,
                                            'last_checkin_longitude' => nil,
                                            'last_checkin_heading' => nil,
                                            'stripe_customer_id' => nil,
                                            'last_checkin_at' => nil,
                                            'wallets' => [],
                                        }
                                    )
  end
end
