class SendResetPasswordNotificationJob
  @queue = :high

  class << self
    def perform(user_id)
      user = User.find(user_id)
      UserMailer.send(:deliver_reset_password_instructions, user)
    end
  end
end
