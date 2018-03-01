class WorkOrderProviderMailer < ActionMailer::Base
  layout 'mailer'
  default from: "#{Settings.app.default_mailer_from_name} <#{Settings.app.default_mailer_from_address || Rails.application.config.default_mailer_from_address}>"
  default template_path: 'mailers/work_order_providers'

  class << self
    def deliver_invitation(invitation)
      invitation(invitation).deliver_now
    end
  end

  def invitation(invitation)
    @invitation = invitation

    return if invitation.invitable.is_a?(WorkOrderProvider) && invitation.invitable.try(:work_order).try(:user)

    provider = invitation.invitable.try(:provider)
    name = provider.try(:contact).try(:name)
    email = provider.try(:contact).try(:email)
    mailto = name && email ? "#{name} <#{email}>" : (email ? email : nil)
    mail(to: mailto,
         subject: 'You have a work order!') if mailto
  end
end
