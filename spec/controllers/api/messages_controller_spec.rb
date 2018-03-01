require 'rails_helper'

describe Api::MessagesController, api: true do
  let(:user)  { FactoryGirl.create(:user) }

  before { sign_in(user) }

  describe '#index' do
    context 'when there is no sender_id provided' do
      let(:messages) { FactoryGirl.create_list(:message, 8, sender: user) }

      before { messages }

      subject { get :index }

      it 'assigns the 8 messages' do
        subject
        expect(assigns(:messages)).to eq(messages)
      end

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'should render the index template' do
        subject
        expect(response).to render_template('index')
      end
    end

    context 'when there is a sender_id query parameter provided' do
      let(:recipient)             { FactoryGirl.create(:user) }
      let(:messages)              { FactoryGirl.create_list(:message, 8, sender: user, recipient: recipient) }
      let(:other_user_messages)   { FactoryGirl.create_list(:message, 8, sender: user) }

      subject { get :index, sender_id: "#{user.id}|#{recipient.id}", recipient_id: "#{user.id}|#{recipient.id}" }

      before { messages && other_user_messages }

      xit 'assigns the 8 messages' do
        subject
        expect(assigns(:messages)).to eq(messages)
      end

      xit 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      xit 'should render the index template' do
        subject
        expect(response).to render_template('index')
      end
    end
  end

  describe '#conversations' do
    let(:sent_messages)     { FactoryGirl.create_list(:message, 3, sender: user, body: Faker::Lorem.paragraphs(3).join('\n\n')) }
    let(:received_messages) { FactoryGirl.create_list(:message, 3, recipient: user, body: Faker::Lorem.paragraphs(3).join('\n\n')) }

    before do
      sent_messages

      3.times do
        received_messages << FactoryGirl.create(:message, recipient: user, sender: received_messages.sample.sender)
      end
    end

    subject { get :conversations }

    it 'assigns the 6 unique conversations' do
      subject
      expect(assigns(:messages).count).to eq(6)
    end

    it 'returns a 200 status code' do
      subject
      expect(response).to have_http_status(200)
    end

    it 'should render the index template' do
      subject
      expect(response).to render_template('index')
    end
  end

  describe '#create' do
    context 'with valid params' do
      let(:recipient) { FactoryGirl.create(:user) }

      subject { post :create, recipient_id: recipient.id, body: Faker::Lorem.paragraphs([1, 2, 3].sample).join('\n\n') }

      it 'assigns :message' do
        subject
        expect(assigns(:message)).to eq(Message.first)
      end

      it 'returns a 201 status code' do
        subject
        expect(response).to have_http_status(201)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end

      it 'sets the sender of the message to the current user' do
        subject
        expect(Message.first.sender).to eq(user)
        expect(user.messages_sent).to eq([Message.first])
      end
    end
  end
end
