require 'rails_helper'

describe Message do

  it { should belong_to(:sender) }
  it { should validate_presence_of(:sender) }

  it { should belong_to(:recipient) }
  it { should validate_presence_of(:recipient) }

  describe '#valid?' do
    let(:message)  { FactoryGirl.create(:message) }

    it 'should not allow the recipient to change' do
      message.update_attributes(recipient: FactoryGirl.create(:user)) && true
      expect(message.errors[:recipient_id]).to include("can't be changed")
    end

    it 'should not allow the sender to change' do
      message.update_attributes(sender: FactoryGirl.create(:user)) && true
      expect(message.errors[:sender_id]).to include("can't be changed")
    end

    it 'should not allow the body to change' do
      message.update_attributes(body: 'This is what I really meant') && true
      expect(message.errors[:body]).to include("can't be changed")
    end

    it 'should not allow the media_url to change' do
      message.update_attributes(media_url: 'https://what.i.really.meant/img.png') && true
      expect(message.errors[:media_url]).to include("can't be changed")
    end
  end

  describe '#create' do
    let(:message) { FactoryGirl.create(:message) }

    before { message }

    it 'should enqueue a PushMessageNotificationsJob in resque' do
      expect(PushMessageNotificationsJob).to have_queued(message.id).in(:high)
    end
  end

  describe '#user_conversations' do
    let(:user)              { FactoryGirl.create(:user) }

    context 'when the user is in multiple conversations' do
      let(:sent_messages)     { FactoryGirl.create_list(:message, 3, sender: user, body: Faker::Lorem.paragraphs(3).join('\n\n')) }
      let(:received_messages) { FactoryGirl.create_list(:message, 3, recipient: user, body: Faker::Lorem.paragraphs(3).join('\n\n')) }

      before do
        3.times do
          received_messages << FactoryGirl.create(:message, recipient: user, sender: received_messages.sample.sender)
        end

        expect(sent_messages.count).to eq(3)
        expect(received_messages.count).to eq(6)
        expect(Message.count).to eq(9)
      end

      let(:user_conversations) { Message.user_conversations(user) }

      it 'should return the 6 unique conversations' do
        expect(user_conversations.reload.size).to eq(6)
      end
    end

    describe 'a single conversation between parties' do
      let(:sending_user)      { FactoryGirl.create(:user) }
      let(:newest_timestamp)  { (DateTime.now + 2.days).to_datetime }
      let(:newest_message)    {
        Timecop.travel(newest_timestamp) do
          FactoryGirl.create(:message, recipient: user, sender: sending_user)
        end
      }

      before do
        newest_message

        3.times do |i|
          Timecop.travel(newest_timestamp - i * 10.hours) do
            FactoryGirl.create(:message, recipient: user, sender: sending_user)
          end
        end
      end

      subject { Message.user_conversations(user) }

      it 'should return a message representing the single unique conversation' do
        expect(subject.size).to eq(1)
      end

      it 'should return the most recent message to represent the conversation' do
        expect(subject.to_a[0].id).to eq(newest_message.id)
      end
    end
  end
end
