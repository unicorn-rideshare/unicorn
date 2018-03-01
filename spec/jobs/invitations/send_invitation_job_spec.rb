require 'rails_helper'

describe SendInvitationJob do
  let(:user)       { FactoryGirl.create(:user) }
  let(:invitation) { FactoryGirl.create(:invitation) }

  before { allow(TwilioService).to receive(:send_sms).with(anything, anything) }

  describe '.perform' do
    subject { SendInvitationJob.perform(invitation.id) }

    context 'when a user is invitable' do
      context 'when the invitation token is a token' do
        it 'should send the invitation using the user mailer' do
          expect(UserMailer).to receive(:deliver_invitation).with(invitation).exactly(1).times
          subject
        end

        it 'should not attempt to deliver the invitation token via SMS' do
          expect(TwilioService).not_to receive(:send_sms)
          subject
        end
      end

      context 'when the invitation token is a pin' do
        let(:invitation) { FactoryGirl.create(:invitation, :pin, invitable: user) }

        context 'when the user contact information does not include a mobile number' do
          it 'should not attempt to send the invitation using the user mailer' do
            expect(UserMailer).not_to receive(:deliver_invitation)
            subject
          end

          it 'should not attempt to send an SMS notification to the customer' do
            expect(TwilioService).not_to receive(:send_sms)
            subject
          end
        end

        context 'when the user contact information contact includes a mobile number' do
          let(:user) { FactoryGirl.create(:user, contact_attributes: FactoryGirl.attributes_for(:contact, mobile: '+15551234')) }

          it 'should send the invitation using the Twilio service' do
            expect(TwilioService).to receive(:send_sms).with(['+15551234'], anything)
            subject
          end

          it 'should not attempt to send the invitation using the user mailer' do
            expect(UserMailer).not_to receive(:deliver_invitation)
            subject
          end
        end
      end
    end
  end
end
