require 'rails_helper'

describe UserMailer, type: :mailer do
  let(:user)        { FactoryGirl.create(:user) }
  let(:sender)      { FactoryGirl.create(:user) }

  describe '.invitation' do
    let(:invitation)  { user.invitations.create(sender: sender) }
    let(:mail) { UserMailer.deliver_invitation(invitation) }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Important Account Activation Instructions')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the user by first name' do
      expect(mail.body.encoded).to match("Hi #{user.name.split(/\s+/)[0]}!")
    end

    it 'includes a link to accept the invitation' do
      matches = mail.body.encoded.match(/http(.*)(\?t=(.*))/i)
      expected_token = matches ? matches[matches.length - 1].strip : nil
      expect(expected_token).to eq(invitation.token)
    end
  end

  describe '.reset_password' do
    let(:mail) { UserMailer.deliver_reset_password_instructions(user) }
    before { user.reset_password }

    it 'sends the email' do
      expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Reset Your Password')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([Settings.app.default_mailer_from_address])
    end

    it 'addresses the user by first name' do
      expect(mail.body.encoded).to match("Hi #{user.name.split(/\s+/)[0]}!")
    end

    it 'includes a link to reset the password' do
      matches = mail.body.encoded.match(/http(.*)(\?t=(.*))/i)
      expected_token = matches ? matches[matches.length - 1].strip : nil
      expect(expected_token).to eq(user.reset_password_token)
    end
  end
end
