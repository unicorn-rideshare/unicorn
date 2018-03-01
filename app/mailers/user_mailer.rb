class UserMailer < ActionMailer::Base
  layout 'mailer'
  default from: "#{Settings.app.default_mailer_from_name} <#{Settings.app.default_mailer_from_address || Rails.application.config.default_mailer_from_address}>"
  default template_path: 'mailers/users'

  class << self
    def deliver_invitation(invitation)
      invitation(invitation).deliver_now
    end

    def deliver_reset_password_instructions(user)
      reset_password(user).deliver_now
    end
  end

  def invitation(invitation)
    @invitation = invitation
    @accept_url = "#{Settings.app.url}/#/accept-invitation?t=#{invitation.token}"

    name = invitation.invitable.try(:name)
    email = invitation.invitable.try(:email)
    mailto = name ? "#{name} <#{email}>" : email
    mail(to: mailto,
         subject: 'Important Account Activation Instructions') if email
  end

  def reset_password(user)
    @user = user
    @reset_url = "#{Settings.app.url}/#/reset-password?t=#{user.reset_password_token}"

    mail(to: "#{user.name} <#{user.email}>",
         subject: 'Reset Your Password')
  end
end
