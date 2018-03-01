class SendInvitationJob
  @queue = :high

  class << self
    def perform(invitation_id)
      invitation = Invitation.find(invitation_id)
      return unless invitation

      mailer_class = "#{invitation.invitable_type}Mailer".constantize
      mailer_class.send(:deliver_invitation, invitation) unless invitation.is_pin?

      if invitation.is_pin?
        contact = invitation.invitable.try(:contact)
        sender_name = invitation.sender ? invitation.sender.name : nil
        send_sms = contact && contact.mobile && sender_name
        body = I18n.t('invitations.pin.sms_body').gsub(/\{\{ first_name \}\}/i, contact.first_name).gsub(/\{\{ sender_name \}\}/i, sender_name).gsub(/\{\{ pin \}\}/i, invitation.token) if send_sms
        TwilioService.send_sms([contact.mobile], body) if send_sms
      end
    end
  end
end
