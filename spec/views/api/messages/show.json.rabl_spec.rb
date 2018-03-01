require 'rails_helper'

describe 'api/messages/show' do
  let(:recipient)   { FactoryGirl.create(:user, name: 'Joe Recipient') }
  let(:sender)      { FactoryGirl.create(:user, name: 'Joe Sender') }
  let(:message)     { FactoryGirl.create(:message,
                                         recipient: recipient,
                                         sender: sender,
                                         body: 'The message body!!!') }

  it 'should render message' do
    @message = message
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => message.id,
                                        'created_at' => message.created_at.iso8601,
                                        'sender_id' => sender.id,
                                        'sender_name' => 'Joe Sender',
                                        'recipient_id' => recipient.id,
                                        'recipient_name' => 'Joe Recipient',
                                        'body' => 'The message body!!!',
                                        'media_url' => nil,
                                        'sender_profile_image_url' => nil
                                    )
  end
end
