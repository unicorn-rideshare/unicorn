require 'rails_helper'

describe 'api/comments/show' do
  let(:user)  { FactoryGirl.create(:user) }
  let(:comment) { FactoryGirl.create(:comment,
                                     user: user,
                                     latitude: 90.0,
                                     longitude: 120.0,
                                     body: 'some comment!!!!') }

  it 'should render comment' do
    @comment = comment
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => comment.id,
                                        'commentable_id' => comment.commentable_id,
                                        'commentable_type' => nil,
                                        'created_at' => comment.created_at.iso8601,
                                        'body' => 'some comment!!!!',
                                        'latitude' => 90.0,
                                        'longitude' => 120.0,
                                        'attachments' => [],
                                        'previous_comment_id' => nil,
                                        'user' => {
                                            'id' => user.id,
                                            'name' => user.name,
                                            'email' => user.email,
                                            'profile_image_url' => user.profile_image_url,
                                            'company_ids' => [],
                                            'provider_ids' => [],
                                            'default_company_id' => nil,
                                            'stripe_customer_id' => nil,
                                            'last_checkin_latitude' => nil,
                                            'last_checkin_longitude' => nil,
                                            'last_checkin_heading' => nil,
                                            'last_checkin_at' => nil,
                                            'wallets' => [],
                                        }
                                    )
  end
end
