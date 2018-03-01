require 'rails_helper'

describe SendResetPasswordNotificationJob do
  let(:user) { FactoryGirl.create(:user) }
  before { user.reset_password }

  describe '.perform' do
    it 'sends the reset password notification using the user mailer' do
      expect(UserMailer).to receive(:deliver_reset_password_instructions).with(user).exactly(1).times
      SendResetPasswordNotificationJob.perform(user.id)
    end
  end
end
